import 'package:flutter/material.dart';
import 'dart:math';


class CharacterWidget extends StatelessWidget {




  @override
  Widget build(BuildContext context) {
    int randomInt = Random().nextInt(3)+1;
    Image characterImage = Image.asset('assets/SourceImages/character$randomInt.png');
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: Theme.of(context).colorScheme.primary,
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Theme.of(context).colorScheme.secondary,
            child: characterImage,
          )


        ),
      ],
    );
  }
}
