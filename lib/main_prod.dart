import 'package:delivery_go/bootstrap.dart';
import 'package:delivery_go/core/app/main_app.dart';
import 'package:delivery_go/core/common/enum.dart';

Future<void> main() async {
  bootstrap(() => const MainApp(), environment: Environment.PROD);
}
