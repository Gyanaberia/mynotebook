import 'package:flutter/material.dart';

class MyCard extends StatefulWidget {
  final String cardTitle;
  // final String cardContent;
  const MyCard(this.cardTitle, {super.key});
  @override
  State<MyCard> createState() => _MyCardState();
}

class _MyCardState extends State<MyCard> {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Card(
        child: InkWell(
          splashColor: Colors.blue.withAlpha(30),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: <Widget>[
                Text(widget.cardTitle),
                const Spacer(),
                const ButtonBar()
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class CardsIcons {}
