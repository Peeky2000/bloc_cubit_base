import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:delivery_go/core/base_component/base_app_state.dart';
import 'package:delivery_go/core/common/enum.dart';

class LoadingScreen<B extends StateStreamable<S>, S extends BaseAppState>
    extends StatelessWidget {
  final Widget Function(BuildContext, S) builder;
  final bool dismissible;
  final double opacity;
  final Color color;
  final BlocBuilderCondition<S>? buildWhen;
  final Function(BuildContext, S)? listener;

  const LoadingScreen({
    Key? key,
    required this.builder,
    this.opacity = 0.3,
    this.color = Colors.black,
    this.dismissible = false,
    this.buildWhen,
    this.listener,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocListener<B, S>(
      listener: (context, state) {
        if (listener != null) {
          listener!(context, state);
        }
      },
      child: Stack(
        children: [
          BlocBuilder<B, S>(
              buildWhen:
                  buildWhen ?? (current, old) => current.loading != old.loading,
              builder: (context, state) => builder(context, state)),
          BlocBuilder<B, S>(
            buildWhen: (previous, current) =>
                previous.loading != current.loading,
            builder: (_, state) {
              return state.loading == LoadingStatus.loading
                  ? Stack(
                      alignment: Alignment.center,
                      children: [
                        Opacity(
                          opacity: opacity,
                          child: ModalBarrier(
                              dismissible: dismissible, color: color),
                        ),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8.0)),
                          child: const CupertinoActivityIndicator(
                            radius: 14,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox();
            },
          ),
        ],
      ),
    );
  }
}
