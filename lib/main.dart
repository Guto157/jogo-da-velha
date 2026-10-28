import 'package:flutter/material.dart';
import 'game_logic.dart';
import 'ai.dart';
import 'multiplayer/wifi_service.dart';

void main() => runApp(MaterialApp(home: MenuScreen(), debugShowCheckedModeBanner: false, theme: ThemeData.dark()));

class MenuScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(gradient: LinearGradient(colors: [Color(0xFF0F172A), Color(0xFF1E293B)], begin: Alignment.topCenter, end: Alignment.bottomCenter)),
        child: Center(
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.grid_3x3, size: 90, color: Colors.cyanAccent),
            SizedBox(height: 10),
            Text('JOGO DA VELHA', style: TextStyle(fontSize: 36, fontWeight: FontWeight.w900, letterSpacing: 2)),
            Text('5 NÍVEIS + MULTIPLAYER', style: TextStyle(color: Colors.white54, letterSpacing: 1)),
            SizedBox(height: 50),
            menuBtn(context, '🤖 JOGAR SOZINHO', Colors.cyan, () => Navigator.push(context, MaterialPageRoute(builder: (_) => DifficultyScreen()))),
            menuBtn(context, '📶 WI-FI', Colors.greenAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => WifiScreen()))),
            menuBtn(context, '🔵 BLUETOOTH', Colors.blueAccent, () => Navigator.push(context, MaterialPageRoute(builder: (_) => BluetoothScreen()))),
          ]),
        ),
      ),
    );
  }
  Widget menuBtn(BuildContext c, String t, Color col, VoidCallback f) => Container(
    margin: EdgeInsets.symmetric(vertical: 8), width: 280, height: 55,
    child: ElevatedButton(onPressed: f, style: ElevatedButton.styleFrom(backgroundColor: col, foregroundColor: Colors.black, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))), child: Text(t, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16))));
}

class DifficultyScreen extends StatelessWidget {
  final levels = [
    {'name':'Fácil', 'desc':'Começando', 'color':Colors.green},
    {'name':'Normal', 'desc':'Defende jogadas', 'color':Colors.yellow},
    {'name':'Difícil', 'desc':'Pensa 3 jogadas', 'color':Colors.orange},
    {'name':'Avançado', 'desc':'Quase imbatível', 'color':Colors.redAccent},
    {'name':'Expert', 'desc':'IMPOSSÍVEL VENCER', 'color':Colors.purpleAccent},
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Escolha a dificuldade'), backgroundColor: Color(0xFF0F172A)),
      body: ListView.builder(padding: EdgeInsets.all(16), itemCount: levels.length, itemBuilder: (_, i) {
        var l = levels[i];
        return Card(color: Color(0xFF1E293B), margin: EdgeInsets.all(8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          child: ListTile(leading: CircleAvatar(backgroundColor: l['color'] as Color, child: Text('${i+1}', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
            title: Text(l['name'] as String, style: TextStyle(fontWeight: FontWeight.bold)), subtitle: Text(l['desc'] as String),
            trailing: Icon(Icons.play_arrow_rounded, color: l['color'] as Color, size: 35),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(difficulty: l['name'] as String, vsCpu: true))),
          ));
      }));
  }
}

class GameScreen extends StatefulWidget {
  final String difficulty; final bool vsCpu; final bool isWifiHost; final String? wifiIp;
  GameScreen({required this.difficulty, this.vsCpu=true, this.isWifiHost=false, this.wifiIp});
  @override _GameScreenState createState() => _GameScreenState();
}
class _GameScreenState extends State<GameScreen> {
  List<String> board = List.filled(9, ''); String turn = 'X'; AI ai = AI(); WifiService? wifi; String status = '';
  int scoreX=0, scoreO=0;
  @override void initState() {
    super.initState();
    if (widget.wifiIp != null || widget.isWifiHost) {
      wifi = WifiService();
      wifi!.onData = (data) => setState(() { int idx = int.tryParse(data.trim()) ?? -1; if(idx>=0 && idx<9 && board[idx]==''){ board[idx]=turn; turn=turn=='X'?'O':'X'; check(); } });
      if(widget.isWifiHost) wifi!.host().then((ip)=> setState(()=> status='IP: $ip'));
      else wifi!.connect(widget.wifiIp!);
    }
  }
  void play(int i){
    if(board[i]!='' || GameLogic.checkWinner(board)!=null) return;
    setState((){ board[i]=turn; wifi?.send(i.toString()); turn=turn=='X'?'O':'X'; });
    check();
    if(widget.vsCpu && turn=='O' && GameLogic.checkWinner(board)==null){
      Future.delayed(Duration(milliseconds: 600), (){ int m = ai.getMove(board, 'O', widget.difficulty); if(m!=-1) play(m); });
    }
  }
  void check(){
    String? w = GameLogic.checkWinner(board);
    if(w!=null){
      if(w=='X') scoreX++; if(w=='O') scoreO++;
      showDialog(context: context, barrierDismissible: false, builder: (_) => AlertDialog(
        backgroundColor: Color(0xFF1E293B), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Center(child: Text(w=='VELHA'?'🤝 DEU VELHA!': w=='X'?'🎉 X VENCEU!':'🤖 O VENCEU!', style: TextStyle(fontWeight: FontWeight.bold))),
        actions: [Center(child: ElevatedButton(onPressed: (){ Navigator.pop(context); setState(()=> board=List.filled(9,'')); }, child: Text('JOGAR NOVAMENTE')))],
      ));
    }
  }
  @override Widget build(BuildContext context) {
    return Scaffold(backgroundColor: Color(0xFF0F172A),
      appBar: AppBar(title: Text('${widget.difficulty}'), backgroundColor: Colors.transparent, centerTitle: true,
        titleTextStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
      body: Column(children: [
        if(status.isNotEmpty) Container(margin: EdgeInsets.all(10), padding: EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(10)), child: Text(status, style: TextStyle(color: Colors.greenAccent))),
        SizedBox(height: 20),
        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          scoreCard('X', scoreX, turn=='X'), scoreCard('O', scoreO, turn=='O'),
        ]),
        SizedBox(height: 20),
        Expanded(child: Center(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(25), boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20)]),
          child: GridView.builder(shrinkWrap: true, gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10),
            itemCount: 9, itemBuilder: (_, i) => GestureDetector(onTap: ()=> play(i),
              child: Container(decoration: BoxDecoration(color: Color(0xFF0F172A), borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.white10)),
                child: Center(child: Text(board[i], style: TextStyle(fontSize: 50, fontWeight: FontWeight.bold, color: board[i]=='X'?Colors.cyanAccent:Colors.pinkAccent))),
              ))),
        ))),
        SizedBox(height: 30),
        Text('Vez do ${turn}', style: TextStyle(color: Colors.white70)),
        SizedBox(height: 40),
      ]),
    );
  }
  Widget scoreCard(String p, int s, bool active) => AnimatedContainer(duration: Duration(milliseconds: 200), padding: EdgeInsets.symmetric(horizontal: 25, vertical: 12),
    decoration: BoxDecoration(color: active?Colors.white:Colors.white10, borderRadius: BorderRadius.circular(15), border: active?Border.all(color: p=='X'?Colors.cyanAccent:Colors.pinkAccent, width: 2):null),
    child: Column(children: [Text(p, style: TextStyle(color: active?Colors.black:Colors.white54, fontWeight: FontWeight.bold)), Text('$s', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: active?Colors.black:Colors.white))]));
}

class WifiScreen extends StatefulWidget { @override _WifiScreenState createState()=> _WifiScreenState(); }
class _WifiScreenState extends State<WifiScreen> {
  TextEditingController ipCtrl = TextEditingController();
  @override Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Wi-Fi')), body: Padding(padding: EdgeInsets.all(20), child: Column(children: [
      Card(child: ListTile(title: Text('CRIAR SALA'), subtitle: Text('Gera seu IP pra amigo conectar'), onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(difficulty: 'Multi', vsCpu: false, isWifiHost: true))))),
      SizedBox(height: 20), TextField(controller: ipCtrl, decoration: InputDecoration(labelText: 'IP do amigo', border: OutlineInputBorder(), prefixIcon: Icon(Icons.wifi))),
      SizedBox(height: 10), ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GameScreen(difficulty: 'Multi', vsCpu: false, wifiIp: ipCtrl.text))), child: Text('ENTRAR NA SALA'))
    ])));
  }
}
class BluetoothScreen extends StatelessWidget { @override Widget build(BuildContext context) { return Scaffold(appBar: AppBar(title: Text('Bluetooth')), body: Center(child: Text('Em breve - use Wi-Fi por enquanto'))); } }
