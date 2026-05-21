with open("packages/nexora_sdk_web/lib/nexora_sdk_web.dart", "r") as f:
    content = f.read()

content = content.replace("!nav.hasProperty('getBattery'.toJS).isTruthy", "!nav.hasProperty('getBattery'.toJS).toDart")
content = content.replace("await promise.toDart as JSObject", "(await promise.toDart)! as JSObject")
content = content.replace("batteryManager.getProperty('level'.toJS) as JSNumber", "(batteryManager.getProperty('level'.toJS))! as JSNumber")
content = content.replace("batteryManager.getProperty('charging'.toJS) as JSBoolean", "(batteryManager.getProperty('charging'.toJS))! as JSBoolean")
content = content.replace("!nav.hasProperty('geolocation'.toJS).isTruthy", "!nav.hasProperty('geolocation'.toJS).toDart")
content = content.replace("nav.getProperty('geolocation'.toJS) as JSObject", "(nav.getProperty('geolocation'.toJS))! as JSObject")
content = content.replace("position.getProperty('coords'.toJS) as JSObject", "(position.getProperty('coords'.toJS))! as JSObject")
content = content.replace("coords.getProperty('latitude'.toJS) as JSNumber", "(coords.getProperty('latitude'.toJS))! as JSNumber")
content = content.replace("coords.getProperty('longitude'.toJS) as JSNumber", "(coords.getProperty('longitude'.toJS))! as JSNumber")
content = content.replace("coords.getProperty('altitude'.toJS) as JSNumber?", "(coords.getProperty('altitude'.toJS)) as JSNumber?")
content = content.replace("coords.getProperty('accuracy'.toJS) as JSNumber", "(coords.getProperty('accuracy'.toJS))! as JSNumber")
content = content.replace("coords.getProperty('speed'.toJS) as JSNumber?", "(coords.getProperty('speed'.toJS)) as JSNumber?")

with open("packages/nexora_sdk_web/lib/nexora_sdk_web.dart", "w") as f:
    f.write(content)
