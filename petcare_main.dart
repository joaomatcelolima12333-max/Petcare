// PetCare – protótipo funcional (Flutter) para DartPad
// Telas: 1) Login  2) Agenda  3) Prontuário / Vacinas / Cobranças
// Sem pacotes externos: basta colar em https://dartpad.dev (modo Flutter).

import 'package:flutter/material.dart';

void main() => runApp(const PetCareApp());

const kTeal = Color(0xFF0F766E);
const kTealDark = Color(0xFF0B5A54);
const kTealLight = Color(0xFFD9EFEC);
const kAmber = Color(0xFFFCE7B2);
const kAmberText = Color(0xFF5C3D00);
const kGrey = Color(0xFFE9ECEB);
const kBg = Color(0xFFF6F7F4);
const kMuted = Color(0xFF5B6B6B);
const kLine = Color(0xFFE1E7E5);

// ───────────────────────── Modelos ─────────────────────────

class Vet {
  final String name, short, spec, crmv;
  const Vet(this.name, this.short, this.spec, this.crmv);
}

class Pet {
  final String name, species, breed, sex, birth, tutor;
  final double weight;
  const Pet(this.name, this.species, this.breed, this.sex, this.birth,
      this.weight, this.tutor);
}

class Appt {
  final String pet, tutor, service;
  String status; // Confirmada | Em atendimento | Concluída
  Appt(this.pet, this.tutor, this.service, [this.status = 'Confirmada']);
}

class Rec {
  final DateTime date;
  final String vet, crmv, complaint, diagnosis, conduct;
  final String? rectifies; // data do registro original (RN07)
  Rec(this.date, this.vet, this.crmv, this.complaint, this.diagnosis,
      this.conduct,
      {this.rectifies});
}

class Vaccine {
  final String name, lot;
  final DateTime applied;
  final DateTime? next;
  Vaccine(this.name, this.lot, this.applied, this.next);
}

class Charge {
  final String desc;
  final double value;
  final DateTime date;
  bool paid;
  String? method;
  Charge(this.desc, this.value, this.date, {this.paid = false, this.method});
}

// ───────────────────────── Estado / dados ─────────────────────────

const vets = [
  Vet('Dra. Helena Duarte', 'Helena', 'Clínica geral', 'CRMV-SP 00001'),
  Vet('Dr. Rafael Lima', 'Rafael', 'Dermatologia', 'CRMV-SP 00002'),
  Vet('Dra. Camila Prado', 'Camila', 'Vacinação', 'CRMV-SP 00003'),
];

const services = {
  'Consulta': 150.0,
  'Retorno': 80.0,
  'Vacina': 90.0,
  'Exame': 200.0,
};

const slotCount = 20; // 08:00 às 17:30, consultas de 30 min (RN01)

String slotLabel(int i) {
  final m = 8 * 60 + 30 * i;
  return '${(m ~/ 60).toString().padLeft(2, '0')}:${(m % 60).toString().padLeft(2, '0')}';
}

String fmt(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

String money(double v) => 'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',')}';

DateTime dayOnly(DateTime d) => DateTime(d.year, d.month, d.day);

class Store extends ChangeNotifier {
  String role = 'Recepcionista';

  final pets = const [
    Pet('Thor', 'Cão', 'Golden Retriever', 'Macho', '12/03/2022', 32.4,
        'Maria Souza'),
    Pet('Luna', 'Gata', 'Siamês', 'Fêmea', '05/09/2021', 4.1, 'Carlos Neri'),
    Pet('Mel', 'Cão', 'Poodle', 'Fêmea', '20/01/2020', 6.8, 'Ana Reis'),
  ];

  final Map<String, Appt> appts = {};
  final Map<String, List<Rec>> records = {};
  final Map<String, List<Vaccine>> vaccines = {};
  final Map<String, List<Charge>> charges = {};

  Store() {
    final t = dayOnly(DateTime.now());
    appts[key(t, 0, 2)] = Appt('Luna', 'Carlos Neri', 'Exame', 'Em atendimento');
    appts[key(t, 0, 5)] = Appt('Thor', 'Maria Souza', 'Retorno');
    appts[key(t, 1, 3)] = Appt('Mel', 'Ana Reis', 'Consulta');
    appts[key(t, 2, 1)] = Appt('Mel', 'Ana Reis', 'Vacina');
    appts[key(t, 2, 8)] = Appt('Thor', 'Maria Souza', 'Vacina');

    records['Thor'] = [
      Rec(DateTime(2026, 11, 2), vets[0].name, vets[0].crmv,
          'Coceira intensa nas orelhas há uma semana.', 'Otite externa leve.',
          'Limpeza auricular e medicação tópica por 7 dias.'),
      Rec(DateTime(2026, 10, 19), vets[1].name, vets[1].crmv,
          'Perda de apetite e apatia.', 'Gastrite leve.',
          'Dieta leve e protetor gástrico por 5 dias.'),
      Rec(DateTime(2026, 8, 5), vets[0].name, vets[0].crmv,
          'Check-up anual.', 'Animal saudável.', 'Manter rotina e vacinas.'),
    ];
    records['Luna'] = [
      Rec(DateTime(2026, 9, 12), vets[0].name, vets[0].crmv,
          'Vômitos ocasionais.', 'Bola de pelo.', 'Malte e escovação diária.'),
    ];
    records['Mel'] = [];

    vaccines['Thor'] = [
      Vaccine('V10 (múltipla)', 'V10-2291', DateTime(2025, 11, 23),
          dayOnly(DateTime.now()).add(const Duration(days: 5))),
      Vaccine('Antirrábica', 'AR-4417', DateTime(2026, 3, 15),
          DateTime(2027, 3, 15)),
      Vaccine('Gripe canina', 'GC-0873', DateTime(2026, 6, 10),
          DateTime(2027, 6, 10)),
    ];
    vaccines['Luna'] = [
      Vaccine('Tríplice felina', 'TF-1102', DateTime(2026, 2, 3),
          DateTime(2027, 2, 3)),
    ];
    vaccines['Mel'] = [];

    charges['Thor'] = [
      Charge('Consulta de retorno', 80, DateTime(2026, 11, 2)),
      Charge('Consulta', 150, DateTime(2026, 10, 19),
          paid: true, method: 'PIX'),
    ];
    charges['Luna'] = [];
    charges['Mel'] = [];
  }

  String key(DateTime d, int vet, int slot) =>
      '${d.year}-${d.month}-${d.day}|$vet|$slot';

  Pet petByName(String n) => pets.firstWhere((p) => p.name == n);

  // RN04: só datas futuras, com antecedência mínima de 2 h.
  bool canBook(DateTime day, int slot) {
    final m = 8 * 60 + 30 * slot;
    final start = DateTime(day.year, day.month, day.day, m ~/ 60, m % 60);
    return start.isAfter(DateTime.now().add(const Duration(hours: 2)));
  }

  void book(DateTime day, int vet, int slot, Pet pet, String service) {
    final k = key(day, vet, slot);
    if (appts.containsKey(k)) return; // RN02
    appts[k] = Appt(pet.name, pet.tutor, service);
    notifyListeners();
  }

  void cancel(String k) {
    appts.remove(k);
    notifyListeners();
  }

  void setStatus(Appt a, String s) {
    a.status = s;
    // RF15 / RN10: cobrança gerada ao concluir o atendimento.
    if (s == 'Concluída') {
      charges[a.pet]!.insert(
          0,
          Charge(a.service, services[a.service] ?? 0, DateTime.now()));
    }
    notifyListeners();
  }

  void addRecord(String pet, Rec r) {
    records[pet]!.insert(0, r);
    notifyListeners();
  }

  void addVaccine(String pet, Vaccine v) {
    vaccines[pet]!.insert(0, v);
    notifyListeners();
  }

  void pay(Charge c, String method) {
    c.paid = true;
    c.method = method;
    notifyListeners();
  }
}

final store = Store();

// ───────────────────────── App ─────────────────────────

class PetCareApp extends StatelessWidget {
  const PetCareApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PetCare',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: kTeal, primary: kTeal),
        scaffoldBackgroundColor: kBg,
      ),
      home: const LoginPage(),
    );
  }
}

// ───────────────────────── Tela 1: Login ─────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _senha = TextEditingController();
  bool _hide = true;
  String _role = 'Recepcionista';

  void _enter() {
    if (!_form.currentState!.validate()) return;
    store.role = _role;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(builder: (context, c) {
        final wide = c.maxWidth >= 800;
        return Row(children: [
          if (wide) Expanded(flex: 5, child: _brandPanel()),
          Expanded(
            flex: 6,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 400),
                  child: _formPanel(showLogo: !wide),
                ),
              ),
            ),
          ),
        ]);
      }),
    );
  }

  Widget _brandPanel() => Container(
        color: kTeal,
        padding: const EdgeInsets.all(56),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _Logo(light: true),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Agenda, prontuário e vacinas num só lugar.',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.1,
                      fontWeight: FontWeight.w700)),
              SizedBox(height: 16),
              Text(
                  'Cadastros de tutores e animais, consultas, atendimentos e cobranças da clínica em um sistema simples de usar.',
                  style: TextStyle(
                      color: Color(0xFFD5EFEC), fontSize: 16, height: 1.5)),
            ]),
            SizedBox(),
          ],
        ),
      );

  Widget _formPanel({required bool showLogo}) {
    return Form(
      key: _form,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (showLogo) ...[const _Logo(), const SizedBox(height: 28)],
        const Text('Entrar',
            style: TextStyle(fontSize: 30, fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text(
            'Use seu e-mail e senha. Você será direcionado às funções do seu perfil.',
            style: TextStyle(color: kMuted)),
        const SizedBox(height: 22),
        TextFormField(
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          decoration: _dec('E-mail', 'nome@exemplo.com'),
          validator: (v) => (v == null || !v.contains('@') || !v.contains('.'))
              ? 'Informe um e-mail válido'
              : null,
        ),
        const SizedBox(height: 16),
        TextFormField(
          controller: _senha,
          obscureText: _hide,
          decoration: _dec('Senha', '••••••').copyWith(
            suffixIcon: IconButton(
              tooltip: _hide ? 'Mostrar senha' : 'Ocultar senha',
              icon: Icon(_hide ? Icons.visibility : Icons.visibility_off),
              onPressed: () => setState(() => _hide = !_hide),
            ),
          ),
          validator: (v) =>
              (v == null || v.length < 6) ? 'Mínimo de 6 caracteres' : null,
          onFieldSubmitted: (_) => _enter(),
        ),
        const SizedBox(height: 18),
        const Text('ENTRAR COMO (simulação de perfil)',
            style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
        const SizedBox(height: 8),
        Wrap(spacing: 8, runSpacing: 8, children: [
          for (final r in ['Tutor', 'Recepcionista', 'Veterinário', 'Administrador'])
            ChoiceChip(
              label: Text(r),
              selected: _role == r,
              onSelected: (_) => setState(() => _role = r),
            ),
        ]),
        const SizedBox(height: 22),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: FilledButton(
            onPressed: _enter,
            child: const Text('Entrar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFE8F0EE),
              borderRadius: BorderRadius.circular(10)),
          child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.lock_outline, size: 18, color: kTeal),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                  'Conexão segura (HTTPS). A sessão expira após 30 minutos sem atividade. Dados tratados conforme a LGPD.',
                  style: TextStyle(fontSize: 12.5, height: 1.4)),
            ),
          ]),
        ),
      ]),
    );
  }

  InputDecoration _dec(String label, String hint) => InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      );
}

class _Logo extends StatelessWidget {
  final bool light;
  const _Logo({this.light = false});
  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
            color: light ? Colors.white : kTeal,
            borderRadius: BorderRadius.circular(11)),
        child: Icon(Icons.pets, color: light ? kTeal : Colors.white),
      ),
      const SizedBox(width: 10),
      Text('PetCare',
          style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: light ? Colors.white : const Color(0xFF1B2A2A))),
    ]);
  }
}

// ───────────────────────── Shell (menu) ─────────────────────────

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _i = 0;

  void _logout() => Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginPage()));

  @override
  Widget build(BuildContext context) {
    final pages = const [AgendaPage(), ProntuarioPage()];
    return LayoutBuilder(builder: (context, c) {
      final wide = c.maxWidth >= 800;
      final dests = const [
        NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Agenda'),
        NavigationDestination(
            icon: Icon(Icons.description_outlined),
            selectedIcon: Icon(Icons.description),
            label: 'Prontuário'),
      ];
      if (wide) {
        return Scaffold(
          body: Row(children: [
            Container(
              width: 220,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(14, 24, 14, 16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Padding(
                    padding: EdgeInsets.only(left: 4), child: _Logo()),
                const SizedBox(height: 24),
                for (var k = 0; k < dests.length; k++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: ListTile(
                      selected: _i == k,
                      selectedTileColor: kTeal,
                      selectedColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      leading: _i == k ? dests[k].selectedIcon : dests[k].icon,
                      title: Text(dests[k].label),
                      onTap: () => setState(() => _i = k),
                    ),
                  ),
                const Spacer(),
                ListTile(
                  tileColor: kBg,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  leading: const CircleAvatar(
                      backgroundColor: kAmber,
                      child: Icon(Icons.person, color: kAmberText)),
                  title: Text(store.role,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Sair'),
                  onTap: _logout,
                ),
              ]),
            ),
            Expanded(child: pages[_i]),
          ]),
        );
      }
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          title: const _Logo(),
          actions: [
            IconButton(
                tooltip: 'Sair', onPressed: _logout, icon: const Icon(Icons.logout))
          ],
        ),
        body: pages[_i],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _i,
          destinations: dests,
          onDestinationSelected: (k) => setState(() => _i = k),
        ),
      );
    });
  }
}

// ───────────────────────── Tela 2: Agenda ─────────────────────────

class AgendaPage extends StatefulWidget {
  const AgendaPage({super.key});
  @override
  State<AgendaPage> createState() => _AgendaPageState();
}

class _AgendaPageState extends State<AgendaPage> {
  DateTime _day = dayOnly(DateTime.now());

  static const _wd = [
    'Segunda-feira', 'Terça-feira', 'Quarta-feira', 'Quinta-feira',
    'Sexta-feira', 'Sábado', 'Domingo'
  ];

  void _move(int delta) {
    var d = _day.add(Duration(days: delta));
    if (d.weekday == DateTime.sunday) d = d.add(Duration(days: delta)); // RN01
    setState(() => _day = d);
  }

  Color _bg(String s) => s == 'Concluída'
      ? kGrey
      : s == 'Em atendimento'
          ? kAmber
          : kTealLight;

  Color _fg(String s) => s == 'Concluída'
      ? const Color(0xFF4A5757)
      : s == 'Em atendimento'
          ? kAmberText
          : const Color(0xFF0B4F4A);

  void _openFree(int vet, int slot) {
    if (!store.canBook(_day, slot)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Horário indisponível: agende para o futuro, com 2 horas de antecedência (RN04).')));
      return;
    }
    Pet pet = store.pets.first;
    String service = 'Consulta';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: const Text('Nova consulta'),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${vets[vet].name} · ${fmt(_day)} às ${slotLabel(slot)}',
                style: const TextStyle(color: kMuted)),
            const SizedBox(height: 16),
            const Text('Animal', style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<Pet>(
              isExpanded: true,
              value: pet,
              items: [
                for (final p in store.pets)
                  DropdownMenuItem(value: p, child: Text('${p.name} (${p.tutor})'))
              ],
              onChanged: (v) => setD(() => pet = v!),
            ),
            const SizedBox(height: 8),
            const Text('Serviço', style: TextStyle(fontWeight: FontWeight.w600)),
            DropdownButton<String>(
              isExpanded: true,
              value: service,
              items: [
                for (final s in services.keys)
                  DropdownMenuItem(value: s, child: Text('$s · ${money(services[s]!)}'))
              ],
              onChanged: (v) => setD(() => service = v!),
            ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                store.book(_day, vet, slot, pet, service);
                Navigator.pop(ctx);
              },
              child: const Text('Agendar'),
            ),
          ],
        ),
      ),
    );
  }

  void _openAppt(String k, Appt a, int vet, int slot) {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('${a.pet} · ${a.service}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text('Tutor: ${a.tutor}\n${vets[vet].name} · ${slotLabel(slot)} · ${a.status}',
              style: const TextStyle(color: kMuted, height: 1.5)),
          const SizedBox(height: 16),
          Wrap(spacing: 8, runSpacing: 8, children: [
            if (a.status == 'Confirmada')
              FilledButton.tonal(
                  onPressed: () {
                    store.setStatus(a, 'Em atendimento');
                    Navigator.pop(ctx);
                  },
                  child: const Text('Iniciar atendimento')),
            if (a.status != 'Concluída')
              FilledButton(
                  onPressed: () {
                    store.setStatus(a, 'Concluída');
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Atendimento concluído. Cobrança gerada em Prontuário > Cobranças.')));
                  },
                  child: const Text('Concluir e gerar cobrança')),
            if (a.status == 'Confirmada')
              OutlinedButton(
                  onPressed: () {
                    store.cancel(k);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Cancelar consulta')),
          ]),
        ]),
      ),
    );
  }

  Widget _cell(int vet, int slot) {
    final k = store.key(_day, vet, slot);
    final a = store.appts[k];
    if (a != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => _openAppt(k, a, vet, slot),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(color: _bg(a.status), borderRadius: BorderRadius.circular(8)),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${a.pet} · ${a.service}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _fg(a.status))),
            Text(a.tutor,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11.5, color: _fg(a.status))),
          ]),
        ),
      );
    }
    final ok = store.canBook(_day, slot);
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => _openFree(vet, slot),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: ok ? Colors.white : kBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: ok ? const Color(0xFF9FB0AD) : kLine),
        ),
        child: Text(ok ? '+ Livre' : '—',
            style: TextStyle(fontSize: 12, color: ok ? kTealDark : kMuted)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Agenda',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
          Text('${_wd[_day.weekday - 1]}, ${fmt(_day)} · 8h às 18h · consultas de 30 min',
              style: const TextStyle(color: kMuted)),
          const SizedBox(height: 12),
          Row(children: [
            IconButton.outlined(
                tooltip: 'Dia anterior',
                onPressed: () => _move(-1),
                icon: const Icon(Icons.chevron_left)),
            const SizedBox(width: 8),
            OutlinedButton(
                onPressed: () => setState(() => _day = dayOnly(DateTime.now())),
                child: const Text('Hoje')),
            const SizedBox(width: 8),
            IconButton.outlined(
                tooltip: 'Próximo dia',
                onPressed: () => _move(1),
                icon: const Icon(Icons.chevron_right)),
          ]),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: kLine),
                  borderRadius: BorderRadius.circular(14)),
              child: Column(children: [
                Row(children: [
                  const SizedBox(width: 54),
                  for (final v in vets)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                        child: Column(children: [
                          Text(v.short,
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          Text(v.spec,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: kMuted)),
                        ]),
                      ),
                    ),
                ]),
                const Divider(height: 1, color: kLine),
                Expanded(
                  child: ListView.builder(
                    itemCount: slotCount,
                    itemBuilder: (_, s) => SizedBox(
                      height: 54,
                      child: Row(children: [
                        SizedBox(
                            width: 54,
                            child: Text(slotLabel(s),
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 12, color: kMuted))),
                        for (var v = 0; v < vets.length; v++)
                          Expanded(
                              child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: _cell(v, s))),
                      ]),
                    ),
                  ),
                ),
              ]),
            ),
          ),
          const SizedBox(height: 10),
          const Wrap(spacing: 14, runSpacing: 6, children: [
            _Legend(kTealLight, 'Confirmada'),
            _Legend(kAmber, 'Em atendimento'),
            _Legend(kGrey, 'Concluída'),
            _Legend(Colors.white, 'Livre'),
          ]),
        ]),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  final Color color;
  final String label;
  const _Legend(this.color, this.label);
  @override
  Widget build(BuildContext context) => Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: const Color(0xFF9FB0AD)))),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12.5)),
      ]);
}

// ───────────────────────── Tela 3: Prontuário ─────────────────────────

class ProntuarioPage extends StatefulWidget {
  const ProntuarioPage({super.key});
  @override
  State<ProntuarioPage> createState() => _ProntuarioPageState();
}

class _ProntuarioPageState extends State<ProntuarioPage> {
  Pet _pet = store.pets.first;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) => DefaultTabController(
        length: 3,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _header(),
            const SizedBox(height: 8),
            const TabBar(tabs: [
              Tab(text: 'Prontuário'),
              Tab(text: 'Vacinas'),
              Tab(text: 'Cobranças'),
            ]),
            Expanded(
              child: TabBarView(children: [
                _recordsTab(),
                _vaccinesTab(),
                _chargesTab(),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _header() {
    Widget info(String l, String v) => Padding(
          padding: const EdgeInsets.only(right: 24),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
            Text(v, style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
        );
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14), side: const BorderSide(color: kLine)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, runSpacing: 12, children: [
          Container(
            width: 56,
            height: 56,
            margin: const EdgeInsets.only(right: 16),
            decoration: BoxDecoration(color: kTealLight, borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.pets, color: kTeal, size: 30),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              DropdownButton<Pet>(
                value: _pet,
                underline: const SizedBox(),
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF1B2A2A)),
                items: [for (final p in store.pets) DropdownMenuItem(value: p, child: Text(p.name))],
                onChanged: (p) => setState(() => _pet = p!),
              ),
              Text('${_pet.species} · ${_pet.breed}', style: const TextStyle(color: kMuted)),
            ]),
          ),
          info('SEXO', _pet.sex),
          info('NASCIMENTO', _pet.birth),
          info('PESO', '${_pet.weight.toString().replaceAll('.', ',')} kg'),
          info('TUTOR(A)', _pet.tutor),
        ]),
      ),
    );
  }

  Widget _box({required Widget child, Color? color}) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color ?? Colors.white,
            border: Border.all(color: kLine),
            borderRadius: BorderRadius.circular(14)),
        child: child,
      );

  Widget _pill(String t, Color bg, Color fg) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(99)),
        child: Text(t, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
      );

  // ---- Prontuário (RF10, RF11, RN07, RN08)

  Widget _recordsTab() {
    final list = store.records[_pet.name]!;
    return Stack(children: [
      ListView(padding: const EdgeInsets.only(top: 14, bottom: 80), children: [
        const Text('Do mais recente ao mais antigo · registros não podem ser alterados ou apagados',
            style: TextStyle(color: kMuted, fontSize: 13)),
        const SizedBox(height: 10),
        if (list.isEmpty)
          _box(child: const Text('Nenhum atendimento registrado para este animal.')),
        for (final r in list)
          _box(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text(fmt(r.date), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                r.rectifies != null
                    ? _pill('Retificação de ${r.rectifies}', kAmber, kAmberText)
                    : _pill('Concluído', kTealLight, const Color(0xFF0B4F4A)),
              ]),
              Text('${r.vet} · ${r.crmv}', style: const TextStyle(fontSize: 13, color: kMuted)),
              const SizedBox(height: 8),
              _line('QUEIXA', r.complaint),
              _line('DIAGNÓSTICO', r.diagnosis),
              _line('CONDUTA', r.conduct),
              if (r.rectifies == null)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                      onPressed: () => _recordDialog(rectify: r),
                      child: const Text('Retificar')),
                ),
            ]),
          ),
      ]),
      Positioned(
        right: 0,
        bottom: 12,
        child: FloatingActionButton.extended(
          onPressed: () => _recordDialog(),
          icon: const Icon(Icons.add),
          label: const Text('Registrar atendimento'),
        ),
      ),
    ]);
  }

  Widget _line(String l, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 96,
              child: Text(l,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: kMuted))),
          Expanded(child: Text(v, style: const TextStyle(height: 1.35))),
        ]),
      );

  void _recordDialog({Rec? rectify}) {
    final q = TextEditingController();
    final d = TextEditingController();
    final c = TextEditingController();
    final vet = vets[0]; // veterinário logado (simulado)
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text(rectify == null ? 'Registrar atendimento' : 'Retificar registro de ${fmt(rectify.date)}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 420,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text('${_pet.name} · ${vet.name} · ${vet.crmv}', style: const TextStyle(color: kMuted)),
                const SizedBox(height: 12),
                TextField(controller: q, maxLines: 2, decoration: const InputDecoration(labelText: 'Queixa', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: d, maxLines: 2, decoration: const InputDecoration(labelText: 'Diagnóstico', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: c, maxLines: 2, decoration: const InputDecoration(labelText: 'Conduta e orientações', border: OutlineInputBorder())),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!, style: const TextStyle(color: Colors.red)),
                  ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (q.text.trim().isEmpty || d.text.trim().isEmpty || c.text.trim().isEmpty) {
                  setD(() => error = 'Preencha todos os campos.');
                  return;
                }
                store.addRecord(
                  _pet.name,
                  Rec(DateTime.now(), vet.name, vet.crmv, q.text.trim(), d.text.trim(), c.text.trim(),
                      rectifies: rectify == null ? null : fmt(rectify.date)),
                );
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Vacinas (RF12, RF13, RN09)

  Widget _vaccinesTab() {
    final list = store.vaccines[_pet.name]!;
    final today = dayOnly(DateTime.now());
    Widget status(Vaccine v) {
      if (v.next == null) return _pill('Aplicada', kGrey, const Color(0xFF4A5757));
      final days = v.next!.difference(today).inDays;
      if (days < 0) return _pill('Reforço atrasado', const Color(0xFFFFD9D2), const Color(0xFF7A1F10));
      if (days <= 7) return _pill('Reforço em $days d', kAmber, kAmberText);
      return _pill('Em dia', kTealLight, const Color(0xFF0B4F4A));
    }

    final soon = list.where((v) => v.next != null && v.next!.difference(today).inDays <= 7).toList();
    return Stack(children: [
      ListView(padding: const EdgeInsets.only(top: 14, bottom: 80), children: [
        for (final v in soon)
          _box(
            color: kAmber,
            child: Row(children: [
              const Icon(Icons.notifications_active_outlined, color: kAmberText),
              const SizedBox(width: 10),
              Expanded(
                  child: Text('Reforço de ${v.name} previsto para ${fmt(v.next!)}.',
                      style: const TextStyle(color: kAmberText, fontWeight: FontWeight.w500))),
            ]),
          ),
        if (list.isEmpty) _box(child: const Text('Nenhuma vacina registrada.')),
        for (final v in list)
          _box(
            child: Row(children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(v.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                  Text('Aplicada ${fmt(v.applied)} · Lote ${v.lot}',
                      style: const TextStyle(fontSize: 12.5, color: kMuted)),
                  if (v.next != null)
                    Text('Próximo reforço: ${fmt(v.next!)}',
                        style: const TextStyle(fontSize: 12.5, color: kMuted)),
                ]),
              ),
              status(v),
            ]),
          ),
      ]),
      Positioned(
        right: 0,
        bottom: 12,
        child: FloatingActionButton.extended(
          onPressed: _vaccineDialog,
          icon: const Icon(Icons.vaccines),
          label: const Text('Registrar vacina'),
        ),
      ),
    ]);
  }

  void _vaccineDialog() {
    final name = TextEditingController();
    final lot = TextEditingController();
    DateTime? next;
    String? error;
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Registrar vacina · ${_pet.name}'),
          content: SingleChildScrollView(
            child: SizedBox(
              width: 400,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(controller: name, decoration: const InputDecoration(labelText: 'Nome da vacina', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(controller: lot, decoration: const InputDecoration(labelText: 'Lote', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.event),
                    label: Text(next == null ? 'Data do próximo reforço (opcional)' : 'Reforço: ${fmt(next!)}'),
                    onPressed: () async {
                      final p = await showDatePicker(
                        context: ctx,
                        initialDate: DateTime.now().add(const Duration(days: 365)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                      );
                      if (p != null) setD(() => next = p);
                    },
                  ),
                ),
                const SizedBox(height: 6),
                Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Data de aplicação: ${fmt(DateTime.now())}',
                        style: const TextStyle(color: kMuted, fontSize: 12.5))),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(error!, style: const TextStyle(color: Colors.red)),
                  ),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                if (name.text.trim().isEmpty || lot.text.trim().isEmpty) {
                  setD(() => error = 'Nome e lote são obrigatórios (RN09).');
                  return;
                }
                store.addVaccine(_pet.name,
                    Vaccine(name.text.trim(), lot.text.trim(), DateTime.now(), next));
                Navigator.pop(ctx);
              },
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
  }

  // ---- Cobranças (RF15, RF16, RF17)

  Widget _chargesTab() {
    final list = store.charges[_pet.name]!;
    final pending = list.where((c) => !c.paid).fold<double>(0, (s, c) => s + c.value);
    return ListView(padding: const EdgeInsets.only(top: 14, bottom: 24), children: [
      _box(
        color: kTealLight,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total pendente', style: TextStyle(fontWeight: FontWeight.w600)),
          Text(money(pending), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
        ]),
      ),
      if (list.isEmpty) _box(child: const Text('Nenhuma cobrança.')),
      for (final c in list)
        _box(
          child: Row(children: [
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c.desc, style: const TextStyle(fontWeight: FontWeight.w700)),
                Text('${fmt(c.date)} · ${money(c.value)}',
                    style: const TextStyle(fontSize: 12.5, color: kMuted)),
              ]),
            ),
            if (c.paid)
              _pill('Pago · ${c.method}', kTealLight, const Color(0xFF0B4F4A))
            else ...[
              _pill('Pendente', kAmber, kAmberText),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: store.role == 'Tutor' ? null : () => _payDialog(c),
                child: const Text('Pagar'),
              ),
            ],
          ]),
        ),
    ]);
  }

  void _payDialog(Charge c) {
    String method = 'PIX';
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          title: Text('Registrar pagamento · ${money(c.value)}'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final m in ['Dinheiro', 'Cartão', 'PIX'])
              ListTile(
                title: Text(m),
                leading: Icon(method == m ? Icons.radio_button_checked : Icons.radio_button_off,
                    color: kTeal),
                onTap: () => setD(() => method = m),
              ),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            FilledButton(
              onPressed: () {
                store.pay(c, method);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context)
                    .showSnackBar(const SnackBar(content: Text('Pagamento registrado. Recibo emitido.')));
              },
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}
