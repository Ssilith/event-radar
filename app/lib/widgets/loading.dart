import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

//* Centred ripple spinner in the primary colour
class Loading extends StatelessWidget {
  //* Spinner diameter (SpinKit's default is 50)
  final double size;
  const Loading({super.key, this.size = 50});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SpinKitRipple(
        color: Theme.of(context).colorScheme.primary,
        size: size,
      ),
    );
  }
}
