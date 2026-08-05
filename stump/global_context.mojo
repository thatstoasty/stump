"""Global default logger and convenience functions."""
from std.ffi import _get_global
from std.collections.dict import DictKeyError, OwnedKwargsDict
from stump.context import Context


def _init_global_ctx() -> Optional[UnsafePointer[NoneType, MutUntrackedOrigin]]:
    """Allocates and constructs the process-wide default context.

    Returns:
        An erased pointer to the constructed context.
    """
    var ptr = alloc[Context](1)

    # `ptr[] = ...` would run the destructor of whatever `alloc` left in this
    # memory, which is garbage rather than a logger. Move into it instead.
    ptr.init_pointee_move(Context())
    return ptr.bitcast[NoneType]()


def _destroy_global_ctx(lib: Optional[UnsafePointer[NoneType, MutUntrackedOrigin]]):
    """Destroys the process-wide default context at exit.

    Args:
        lib: The erased pointer to the constructed context.
    """
    if not lib:
        return

    # The cast has to name the type that was allocated. `free` alone only needs
    # the address, but `destroy_pointee` runs that type's destructor, and running
    # the wrong one would be worse than leaking.
    var ptr = lib.value().bitcast[Context]()
    ptr.destroy_pointee()
    ptr.free()


@always_inline
def global_ctx() -> UnsafePointer[Context, MutUntrackedOrigin]:
    """Gets the process-wide default context, constructing it on first use.

    Returns:
        A mutable pointer to the default context.
    """
    return _get_global["global_ctx", _init_global_ctx, _destroy_global_ctx]().value().bitcast[Context]()


def clear_context():
    """Clears the process-wide default context."""
    global_ctx()[].clear()


def bind_context(**kwargs: Arg):
    """Binds key-value pairs to the process-wide default context.

    Args:
        kwargs: The key-value pairs to bind to the default context.
    """
    ref ctx = global_ctx()[]
    for pair in kwargs.items():
        ctx[pair.key] = String(pair.value)


def bind_context(kwargs: OwnedKwargsDict[Arg]):
    """Binds key-value pairs to the process-wide default context.

    Args:
        kwargs: The key-value pairs to bind to the default context.
    """
    ref ctx = global_ctx()[]
    for pair in kwargs.items():
        ctx[pair.key] = String(pair.value)


def unbind_context(*keys: String) raises DictKeyError[String]:
    """Unbinds keys from the process-wide default context.

    Args:
        keys: The keys to unbind from the default context.

    Raises:
        DictKeyError: If any of the keys to unbind are not present in the context.
    """
    ref ctx = global_ctx()[]
    for key in keys:
        _ = ctx.pop(key)


def unbind_context(kwargs: OwnedKwargsDict[Arg]) raises DictKeyError[String]:
    """Unbinds keys from the process-wide default context.

    Args:
        kwargs: The key-value pairs whose keys to unbind from the default context.

    Raises:
        DictKeyError: If any of the keys to unbind are not present in the context.
    """
    ref ctx = global_ctx()[]
    for key in kwargs.keys():
        _ = ctx.pop(key)


def scoped_context(**kwargs: Arg) -> ScopedContextManager:
    """Creates a new context with the given key-value pairs bound to it.

    Args:
        kwargs: The key-value pairs to bind to the new context.

    Returns:
        A `ScopedContextManager` that manages the temporary binding and unbinding of the key value pairs provided.
    """
    return ScopedContextManager(kwargs^)


@fieldwise_init
struct ScopedContextManager(Copyable):
    """A context manager that temporarily binds key-value pairs to the process-wide default context."""

    var bound_args: OwnedKwargsDict[Arg]
    """The key-value pairs to bind to the new context."""

    def __enter__(self) -> None:
        """Binds the key-value pairs to the process-wide default context."""
        bind_context(self.bound_args)

    def __exit__(self) raises -> None:
        """Unbinds the key-value pairs from the process-wide default context.

        Raises:
            Error: If any of the keys to unbind are not present in the context.
        """
        try:
            unbind_context(self.bound_args)
        except e:
            raise Error(e)
