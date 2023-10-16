import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/data.dart';

class NextBlock extends StatefulWidget {
  const NextBlock({Key? key}) : super(key: key);

  @override
  State<NextBlock> createState() => _NextBlockState();
}

class _NextBlockState extends State<NextBlock> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(5),
        color: Colors.white,
      ),
      width: double.infinity,
      padding: const EdgeInsets.all(5),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Next',
            style: TextStyle(
              fontWeight: FontWeight.bold
            ),
          ),
          const SizedBox(height: 5),
          AspectRatio(
              aspectRatio: 3,
            child: Container(
              color: Colors.indigo.shade600,
              child: Center(
                child: Provider.of<Data>(context, listen: false).getNextBlockWidget(),
              ),
            ),
          )
        ],
      ),
    );
  }
}
