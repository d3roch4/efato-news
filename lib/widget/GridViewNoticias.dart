import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:efato/dominio/Noticia.dart';

import '../utils.dart';

class GridViewNoticias extends StatelessWidget{
  List<Noticia> noticias;
  void Function(Noticia) onTap;
  ScrollController scrollController;
  EdgeInsetsGeometry padding;

  GridViewNoticias({this.noticias, this.onTap, this.scrollController, this.padding});

  @override
  Widget build(BuildContext context) {
    return StaggeredGridView.extentBuilder(
      maxCrossAxisExtent: 300,
      staggeredTileBuilder: (int index) =>StaggeredTile.fit(1),
      mainAxisSpacing: kPadding/2,
      crossAxisSpacing: kPadding/2,
      itemCount: noticias.length,
      controller: scrollController,
      padding: padding,
      itemBuilder: (BuildContext context, int index){
        var noticia = noticias[index];

        return GestureDetector(
          onTap: ()=> onTap(noticia),
          child: Card(
            // color: noticia.selo==null? null: Color(noticia.selo.cor),
            shape: RoundedRectangleBorder(
              side: BorderSide(color: noticia.selo==null? Colors.white: Color(noticia.selo.cor), width: 5),
              borderRadius: BorderRadius.circular(20)
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(fit: StackFit.passthrough, children: [
                CachedNetworkImage(
                  imageUrl: noticia.imagem ?? '',
                  fit: BoxFit.fill,
                  errorWidget: (c,u,e)=> Image.asset('assets/icon.png'),
                ),
                Positioned(
                  child: GridTileBar(
                    backgroundColor: Colors.black54,
                    title: Text(noticia.titulo),
                  ),
                  bottom: 0,
                  left: 0,
                  right: 0,
                ),
                if(noticia.selo != null)
                  Positioned(
                    child: Hero(
                      tag: noticia.id,
                      child: CachedNetworkImage(imageUrl: noticia.selo.imagem, height: 50),
                    ),
                    top: 8,
                    right: 8,
                  ),
              ]),
            )
          ),
        );
      },
    );
  }
}