import 'package:mOrder/bootstrap.dart';
import 'package:mOrder/core/app/main_app.dart';
import 'package:mOrder/core/common/enum.dart';

Future<void> main() async {
  bootstrap(() => const MainApp(), environment: Environment.LOCAL);
}
