# delivery_go


#Note
1. Set up project if server use message code
- If server using message code, please uncomment one line in file `main_app.dart`.
```dart
  ServerMessageLocalization.delegate
```
- Add assets:
```yaml
assets:
    - assets/server_localization/
```
- To display error response from server, find file `error_mapper_item.dart` and change return string of function `getDisplay` in `HttpErrorResponseMapperItem` class.<br/>

From
```dart
return result.message;
```
To
```dart
return result.message.messageServerTranslate(Injector.getIt.get<AppController>().context);
```
2. Get JSON file message code from server:
- If server use code message please find file `get_message_code.bash`. In there, you can see 2 variables `arrUrlServerCode`, one in function `getMessageCodeEn` and one in function `getMessageCodeVi`. These variables is array to collect list of url of json file message code and it's content.
- If you want to add more url JSON file, you just add new url into `arrUrlServerCode` variable. Example:
```bash
arrUrlServerCode=(
      "url1"
      "url2"
      ...
    )
```