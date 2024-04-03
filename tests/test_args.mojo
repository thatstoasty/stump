fn info(message: String, /, *args: String, **kwargs: String):
    print("message", message)
    for arg in args:
        print("arg: ", arg[])
    
    for pair in kwargs.items():
        print("key: ", pair[].key)
        print("value: ", pair[].value)


fn main():
    info("Hello", "world", "foo", "bar", key1="value1", key2="value2")