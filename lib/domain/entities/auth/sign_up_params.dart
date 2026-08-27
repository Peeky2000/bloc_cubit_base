import 'package:bloc_cubit_base/domain/entities/common/app_enums.dart';
import 'package:equatable/equatable.dart';

class SignUpParams extends Equatable {
  const SignUpParams({
    required this.email,
    required this.password,
    required this.phone,
    required this.industry,
    required this.shippingScale,
    required this.shopName,
  });

  final String email;
  final String password;
  final String phone;
  final String industry;
  final ScaleLevel shippingScale;
  final String shopName;

  @override
  List<Object> get props => [
    email,
    password,
    phone,
    industry,
    shippingScale,
    shopName,
  ];
}
