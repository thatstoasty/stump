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
    """Clears the process-wide default context.

    This is useful for tests that want to reset the context between runs.
    """
    global_ctx()[].clear()


def bind_context(**kwargs: Arg):
    """Binds key-value pairs to the process-wide default context.

    This is useful for tests that want to set up a context before running code.
    """
    ref ctx = global_ctx()[]
    for pair in kwargs.items():
        ctx[pair.key] = String(pair.value)


def bind_context(kwargs: OwnedKwargsDict[Arg]):
    """Binds key-value pairs to the process-wide default context.

    This is useful for tests that want to set up a context before running code.
    """
    ref ctx = global_ctx()[]
    for pair in kwargs.items():
        ctx[pair.key] = String(pair.value)


def unbind_context(*keys: String) raises DictKeyError[String]:
    """Unbinds keys from the process-wide default context.

    This is useful for tests that want to reset the context between runs.
    """
    ref ctx = global_ctx()[]
    for key in keys:
        _ = ctx.pop(key)


def with_bound_context(**kwargs: Arg) -> TempBoundContext:
    """Creates a new context with the given key-value pairs bound to it.

    This is useful for tests that want to set up a context before running code.
    """
    return TempBoundContext(kwargs^)


@fieldwise_init
struct TempBoundContext(Copyable):
    var bound_args: OwnedKwargsDict[Arg]

    def __enter__(self) -> None:
        """Binds the key-value pairs to the process-wide default context."""
        bind_context(self.bound_args)

    def __exit__(self) -> None:
        clear_context()
