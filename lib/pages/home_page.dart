import 'package:borrowed_stuff/components/centered_circular_progress.dart';
import 'package:borrowed_stuff/components/centered_message.dart';
import 'package:borrowed_stuff/components/stuff_card.dart';
import 'package:borrowed_stuff/controllers/home_controller.dart';
import 'package:borrowed_stuff/models/stuff.dart';
import 'package:borrowed_stuff/pages/stuff_detail_page.dart';
import 'package:flushbar/flushbar.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = HomeController();
  bool _loading = true;
  final GlobalKey<AnimatedListState> _key = GlobalKey();

  @override
  void initState() {
    super.initState();
    _controller.readAll().then((value) {
      setState(() {
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Objetos Emprestados'),
      ),
      floatingActionButton: _buildFloatingActionButton(),
      body: _buildStuffList(),
    );
  }

  _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      label: Text('Emprestar'),
      icon: Icon(Icons.add),
      onPressed: _addStuff,
    );
  }

  _buildItem(index){
    final stuff = _controller.stuffList[index];
    return StuffCard(
      stuff: stuff,
      onTelefonar: (){
        _telefonarStuff(stuff);
      },
      onDelete: () {
        _deleteStuff(stuff, index);
      },
      onEdit: () {
        _editStuff(index, stuff);
      },
    );
  }

  _buildStuffList() {
    if (_loading) {
      return CenteredCircularProgress();
    }

    if (_controller.stuffList.isEmpty) {
      return CenteredMessage('Vazio', icon: Icons.warning);
    }

    return AnimatedList(
      key: _key,
      initialItemCount: _controller.stuffList.length,
      itemBuilder: (context, index, animation) {
        return _buildItem(index);
      },
    );
  }

  _addStuff() async {
    print('New stuff');
    final stuff = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StuffDetailPage()),
    );

    if (stuff != null) {
      setState(() {
        _controller.create(stuff);
      });

      Flushbar(
        title: "Novo empréstimo",
        backgroundColor: Colors.black,
        message: "${stuff.description} emprestado para ${stuff.contactName}.",
        duration: Duration(seconds: 2),
      )..show(context);
    }
  }

  _editStuff(index, stuff) async {
    print('Edit stuff');
    final editedStuff = await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => StuffDetailPage(editedStuff: stuff)),
    );

    if (editedStuff != null) {
      setState(() {
        _controller.update(index, editedStuff);
      });

      Flushbar(
        title: "Empréstimo atualizado",
        backgroundColor: Colors.black,
        message:
            "${editedStuff.description} emprestado para ${editedStuff.contactName}.",
        duration: Duration(seconds: 2),
      )..show(context);
    }
  }

   _telefonarStuff(Stuff stuff){
    try{
      _launchURL(stuff.telephone);
    }catch(e){
      Flushbar(
        title: e,
        backgroundColor: Colors.red,
        message:
            "Tente ligar novamente mais tarde",
        duration: Duration(seconds: 2),
      )..show(context);
    }
  }

  _launchURL(String telefoneEnviar) async {
    String url = 'tel:$telefoneEnviar';

    if (await canLaunch(url)) {
      await launch(url);
    } else {
      throw 'Não foi possível realizar a ligação para $url';
    }
  }

   _deleteStuff(Stuff stuff, int index) {
    print('Delete stuff');
    _controller.delete(stuff);

    AnimatedListRemovedItemBuilder builder = (context, animation){
        return _buildItem(index);
    };

    _key.currentState.removeItem(index, builder);

    Flushbar(
      title: "Exclusão",
      backgroundColor: Colors.red,
      message: "${stuff.description} excluído com sucesso.",
      duration: Duration(seconds: 2),
    )..show(context);
  }
}