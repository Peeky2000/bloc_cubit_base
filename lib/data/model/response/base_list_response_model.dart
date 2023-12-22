import 'package:json_annotation/json_annotation.dart';
import 'package:delivery_go/domain/entities/response/base_list_response.dart';

part 'base_list_response_model.g.dart';

@JsonSerializable(genericArgumentFactories: true)
class BaseListResponseModel<T> implements BaseListResponse<T> {
  BaseListResponseModel(
      {this.message, this.page, this.perPage, this.totalResults, this.data});

  @override
  @JsonKey(name: 'message')
  final String? message;

  @override
  @JsonKey(name: 'page')
  final int? page;

  @override
  @JsonKey(name: 'perPage')
  final int? perPage;

  @override
  @JsonKey(name: 'totalResults')
  final int? totalResults;

  @override
  @JsonKey(name: 'data')
  final List<T>? data;

  factory BaseListResponseModel.fromJson(
          Map<String, dynamic> json, T Function(Object? json) fromJsonT) =>
      _$BaseListResponseModelFromJson(json, fromJsonT);

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$BaseListResponseModelToJson(this, toJsonT);
}
