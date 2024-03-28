from external.morrow import Morrow
from .base import Context


fn add_timestamp(inout context: Context):
    var timestamp: String = ""
    try:
        timestamp = Morrow.now().format("YYYY-MM-DD HH:mm:ss")
        context["timestamp"] = timestamp
    except:
        print("failed to get timestamp")
