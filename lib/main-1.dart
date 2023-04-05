import 'package:flutter/material.dart';

class CircleButton extends StatefulWidget {
  @override
  _CircleButtonState createState() => _CircleButtonState();
}

class _CircleButtonState extends State<CircleButton> {
  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircleAvatar(
          backgroundColor: _selected == 1 ? Colors.blue : Colors.grey,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selected = 1;
              });
            },
          ),
        ),
        SizedBox(width: 10),
        CircleAvatar(
          backgroundColor: _selected == 2 ? Colors.blue : Colors.grey,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selected = 2;
              });
            },
          ),
        ),
        SizedBox(width: 10),
        CircleAvatar(
          backgroundColor: _selected == 3 ? Colors.blue : Colors.grey,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _selected = 3;
              });
            },
          ),
        ),
      ],
    );
  }
}
