import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'ai.dart';
import 'multiplayer/wifi_service.dart';

void main() => runApp(MaterialApp(home: MenuScreen(), debugShowCheckedModeBanner: false));

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F172A),
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text('JOGO DA VELHA', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)),
          SizedBox(height: 40),
          _btn(context, 'JOGAR SOZINHO', () => Navigator.push(context, MaterialPageRoute(builder: (_) => DifficultyScreen()))),
          _btn(context, 'MULTIPLAYER WI-FI', () => Navigator.push(context, MaterialPageRoute(builder: (_) => WifiScreen()))),
          _btn(context, 'MULTIPLAYER BLUETOOTH', () => Navigator.push(context, MaterialPageRoute(builder: (_) => BluetoothScreen()))),
        ]),
      ),
    );
  }
  Widget _btn(BuildContext c, String t, VoidCallback f) => Padding(
    padding: EdgeInsets.all(8),
    child: ElevatedButton(onPressed: f, child: Text(t), style: ElevatedButton.styleFrom(minimumSize: Size(250,50))),
  );
}

class DifficultyScreen extends StatelessWidget {
  final diffs = ['Fácil','Normal','Difícil','Avançado','Expert'];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Escolha a dificuldade')),
      body: ListView(children: diffs.map((d) => ListTile(
        title: Text(d),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(difficulty: d, vsCpu: true))),
      )).toList()),
    );
  }
}

class GameScreen extends StatefulWidget {
  final String difficulty;
  final bool vsCpu;
  final bool isWifiHost;
  final String? wifiIp;
  GameScreen({required this.difficulty, this.vsCpu=true, this.isWifiHost=false, this.wifiIp});
  @override _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  List<String> board = List.filled(9, '');
  String turn = 'X';
  AI ai = AI();
  WifiService? wifi;
  String status = '';

  @override
  void initState() {
    super.initState();
    if (widget.wifiIp != null || widget.isWifiHost) {
      wifi = WifiService();
      wifi!.onData = (data) {
        setState(() {
          int idx = int.tryParse(data.trim()) ?? -1;
          if(idx>=0 && idx<9){ board[idx]= turn; turn = turn=='X'?'O':'X'; }
        });
      };
      if (widget.isWifiHost) {
        wifi!.host().then((ip) => setState(()=> status='Seu IP: $ip - Porta 4040'));
      } else {
        wifi!.connect(widget.wifiIp!);
      }
    }
  }

  void _play(int i) {
    if (board[i]!='' || GameLogic.checkWinner(board)!=null) return;
    setState(() {
      board[i]=turn;
      if (wifi!=null) wifi!.send(i.toString());
      turn = turn=='X'?'O':'X';
    });
    String? winner = GameLogic.checkWinner(board);
    if (winner!=null) { _showEnd(winner); return; }
    if (widget.vsCpu && turn=='O') {
      Future.delayed(Duration(milliseconds: 400), () {
        int aiMove = ai.getMove(board, 'O', widget.difficulty);
        if (aiMove!=-1) _play(aiMove);
      });
    }
  }

  void _showEnd(String w) {
    showDialog(context: context, builder: (_) => AlertDialog(
      title: Text(w=='VELHA'?'Deu velha!':'Vencedor: $w'),
      actions: [TextButton(onPressed: (){ Navigator.pop(context); setState(()=> board=List.filled(9,'') ); }, child: Text('Reiniciar'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('${widget.difficulty} - Vez: $turn')),
      body: Column(children: [
        if (status.isNotEmpty) Padding(padding: EdgeInsets.all(8), child: Text(status)),
        Expanded(child: GridView.builder(gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3),
          itemCount: 9, itemBuilder: (_, i) => GestureDetector(onTap: ()=> _play(i),
            child: Container(margin: EdgeInsets.all(4), color: Colors.blueGrey[100], child: Center(child: Text(board[i], style: TextStyle(fontSize: 48))))),
        )),
      ]),
    );
  }
}

class WifiScreen extends StatefulWidget { @override _WifiScreenState createState()=> _WifiScreenState(); }
class _WifiScreenState extends State<WifiScreen> {
  TextEditingController ipCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Wi-Fi Multiplayer')),
      body: Padding(padding: EdgeInsets.all(20), child: Column(children: [
        ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(difficulty: 'Multi', vsCpu: false, isWifiHost: true))), child: Text('CRIAR SALA (HOST)')),
        SizedBox(height: 20),
        TextField(controller: ipCtrl, decoration: InputDecoration(labelText: 'IP do amigo ex: 192.168.0.5')),
        ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(difficulty: 'Multi', vsCpu: false, wifiIp: ipCtrl.text))), child: Text('ENTRAR NA SALA')),
      ])),
    );
  }
}

class BluetoothScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Bluetooth')),
      body: Center(child: Padding(padding: EdgeInsets.all(20), child: Text('Código Bluetooth em lib/multiplayer/bluetooth_service.dart. Adicione a lib no pubspec e pareie os celulares nas configs.')))),
    );
  }
}
