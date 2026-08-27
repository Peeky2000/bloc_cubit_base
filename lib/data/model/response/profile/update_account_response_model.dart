import 'package:bloc_cubit_base/data/model/response/profile/account_response_model.dart';
import 'package:bloc_cubit_base/domain/entities/profile/update_account.dart';
import 'package:json_annotation/json_annotation.dart';

part 'update_account_response_model.g.dart';

@JsonSerializable()
class UpdateAccountResponseModel implements UpdateAccount {
  UpdateAccountResponseModel({this.account});

  @override
  @JsonKey(name: 'account')
  final AccountResponseModel? account;

  factory UpdateAccountResponseModel.fromJson(Map<String, dynamic> json) =>
      _$UpdateAccountResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateAccountResponseModelToJson(this);
}
