import 'dart:convert';
// ignore: avoid_web_libraries_in_flutter, deprecated_member_use
import 'dart:html' as html;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// Firebase 콘솔 > 프로젝트 설정에서 아래 2개 값만 복사해 넣으세요.
const String firebaseApiKey = 'AIzaSyBAXhSFMEbCVMNB4JpeukGj1WHFrHJUrqk';
const String firebaseProjectId = 'project-a29a1';

void main() {
  runApp(const WeatherMoodApp());
}

class WeatherMoodApp extends StatefulWidget {
  const WeatherMoodApp({super.key});

  @override
  State createState() => _WeatherMoodAppState();
}

class _WeatherMoodAppState extends State<WeatherMoodApp> {
  String? _idToken;
  String? _uid;
  String? _email;

  @override
  void initState() {
    super.initState();
    _idToken = html.window.localStorage['fb_id_token'];
    _uid = html.window.localStorage['fb_uid'];
    _email = html.window.localStorage['fb_email'];
  }

  void _handleLoginSuccess(String idToken, String uid, String email) {
    html.window.localStorage['fb_id_token'] = idToken;
    html.window.localStorage['fb_uid'] = uid;
    html.window.localStorage['fb_email'] = email;
    setState(() {
      _idToken = idToken;
      _uid = uid;
      _email = email;
    });
  }

  void _handleLogout() {
    html.window.localStorage.remove('fb_id_token');
    html.window.localStorage.remove('fb_uid');
    html.window.localStorage.remove('fb_email');
    setState(() {
      _idToken = null;
      _uid = null;
      _email = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoggedIn = _idToken != null && _uid != null;

    return MaterialApp(
      title: '우리 동네 날씨 & 오늘의 기분 기록장',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: isLoggedIn
          ? MainJournalScreen(
              idToken: _idToken!,
              uid: _uid!,
              email: _email ?? '',
              onLogout: _handleLogout,
            )
          : LoginScreen(onLoginSuccess: _handleLoginSuccess),
    );
  }
}

// ==========================================
// 1. Firebase Authentication 로그인 / 회원가입 화면
// ==========================================
class LoginScreen extends StatefulWidget {
  final void Function(String idToken, String uid, String email) onLoginSuccess;

  const LoginScreen({super.key, required this.onLoginSuccess});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _errorMessage;
  bool _isLoading = false;

  Future<void> _authenticate({required bool isSignUp}) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = '이메일과 비밀번호를 모두 입력해 주세요.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final endpoint = isSignUp ? 'accounts:signUp' : 'accounts:signInWithPassword';
    final url = Uri.parse(
      'https://identitytoolkit.googleapis.com/v1/$endpoint?key=$firebaseApiKey',
    );

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        widget.onLoginSuccess(
          data['idToken'] as String,
          data['localId'] as String,
          data['email'] as String,
        );
      } else {
        final rawCode = data['error']?['message']?.toString() ?? 'UNKNOWN_ERROR';
        setState(() => _errorMessage = _mapAuthError(rawCode));
      }
    } catch (e) {
      setState(() => _errorMessage = '네트워크 오류가 발생했습니다: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _mapAuthError(String code) {
    if (code.contains('INVALID_LOGIN_CREDENTIALS') ||
        code.contains('EMAIL_NOT_FOUND') ||
        code.contains('INVALID_PASSWORD')) {
      return '이메일 또는 비밀번호가 올바르지 않습니다.';
    }
    if (code.contains('INVALID_EMAIL')) {
      return '올바른 이메일 형식이 아닙니다.';
    }
    if (code.contains('EMAIL_EXISTS')) {
      return '이미 가입된 이메일입니다.';
    }
    if (code.contains('WEAK_PASSWORD')) {
      return '비밀번호는 6자리 이상이어야 합니다.';
    }
    if (code.contains('API_KEY_INVALID')) {
      return 'Firebase apiKey가 올바르지 않습니다. 코드 상단을 확인해 주세요.';
    }
    return '로그인 실패 ($code)';
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Card(
            margin: const EdgeInsets.all(24),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.wb_sunny_outlined, size: 48, color: Colors.indigo),
                  const SizedBox(height: 12),
                  const Text(
                    '우리 동네 날씨 & 기분 기록장',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: '이메일',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: '비밀번호 (6자 이상)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    onSubmitted: (_) => _authenticate(isSignUp: false),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: TextStyle(color: Colors.red.shade800, fontSize: 13),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _isLoading ? null : () => _authenticate(isSignUp: false),
                    child: _isLoading
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('로그인'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _isLoading ? null : () => _authenticate(isSignUp: true),
                    child: const Text('새 계정으로 회원가입'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 2. 메인 화면 (Open-Meteo 날씨 + Firestore 기록장)
// ==========================================
class MainJournalScreen extends StatefulWidget {
  final String idToken;
  final String uid;
  final String email;
  final VoidCallback onLogout;

  const MainJournalScreen({
    super.key,
    required this.idToken,
    required this.uid,
    required this.email,
    required this.onLogout,
  });

  @override
  State createState() => _MainJournalScreenState();
}

class _MainJournalScreenState extends State<MainJournalScreen> {
  final _cityPresets = {
    '서울': [37.5665, 126.9780],
    '부산': [35.1796, 129.0756],
    '대전': [36.3504, 127.3845],
    '광주': [35.1595, 126.8526],
    '제주': [33.4996, 126.5312],
  };

  String _selectedCity = '서울';
  final _latController = TextEditingController(text: '37.5665');
  final _lonController = TextEditingController(text: '126.9780');
  final _memoController = TextEditingController();

  bool _isWeatherLoading = false;
  String? _weatherError;
  double? _temperature;
  double? _windSpeed;
  int? _weatherCode;

  final _moodOptions = ['😊 행복', '😌 평온', '😐 보통', '😔 우울', '😤 짜증'];
  String _selectedMood = '😊 행복';

  bool _isRecordsLoading = true;
  List _records = [];

  String get _firestoreCollectionUrl =>
      'https://firestore.googleapis.com/v1/projects/$firebaseProjectId/databases/(default)/documents/users/${widget.uid}/records';

  @override
  void initState() {
    super.initState();
    _fetchWeather();
    _loadRecords();
  }

  Future<void> _fetchWeather() async {
    final lat = double.tryParse(_latController.text.trim());
    final lon = double.tryParse(_lonController.text.trim());

    if (lat == null || lon == null) {
      setState(() => _weatherError = '올바른 위도와 경도 숫자를 입력해 주세요.');
      return;
    }

    setState(() {
      _isWeatherLoading = true;
      _weatherError = null;
    });

    try {
      final url = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final current = data['current_weather'];
        setState(() {
          _temperature = (current['temperature'] as num).toDouble();
          _windSpeed = (current['windspeed'] as num).toDouble();
          _weatherCode = current['weathercode'] as int;
        });
      } else {
        setState(() => _weatherError = '날씨 API 호출 실패 (코드: ${response.statusCode})');
      }
    } catch (e) {
      setState(() => _weatherError = '네트워크 오류: $e');
    } finally {
      if (mounted) {
        setState(() => _isWeatherLoading = false);
      }
    }
  }

  String _describeWeatherCode(int? code) {
    if (code == null) return '알 수 없음';
    if (code == 0) return '☀️ 맑음';
    if (code >= 1 && code <= 3) return '⛅ 구름 조금 / 흐림';
    if (code == 45 || code == 48) return '🌫️ 안개';
    if ((code >= 51 && code <= 67) || (code >= 80 && code <= 82)) return '🌧️ 비 / 소나기';
    if ((code >= 71 && code <= 77) || (code >= 85 && code <= 86)) return '❄️ 눈';
    if (code >= 95) return '⛈️ 뇌우';
    return '🌤️ 기타 ($code)';
  }

  Future<void> _loadRecords() async {
    setState(() => _isRecordsLoading = true);
    try {
      final response = await http.get(
        Uri.parse(_firestoreCollectionUrl),
        headers: {'Authorization': 'Bearer ${widget.idToken}'},
      );

      if (response.statusCode == 401) {
        widget.onLogout();
        return;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final docs = (data['documents'] as List?) ?? [];
        final parsed = docs.map((doc) {
          final fullName = doc['name']?.toString() ?? '';
          final docId = fullName.split('/').last;
          final fields = doc['fields'] ?? {};
          return {
            'id': docId,
            'mood': fields['mood']?['stringValue']?.toString() ?? '😊',
            'memo': fields['memo']?['stringValue']?.toString() ?? '',
            'weather': fields['weather']?['stringValue']?.toString() ?? '',
            'clientTime': fields['clientTime']?['stringValue']?.toString() ?? '',
          };
        }).toList();

        parsed.sort((a, b) => (b['clientTime'] ?? '').compareTo(a['clientTime'] ?? ''));

        if (mounted) {
          setState(() => _records = parsed);
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isRecordsLoading = false);
      }
    }
  }

  Future<void> _saveRecord() async {
    final memo = _memoController.text.trim();
    if (memo.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘의 한 줄 기록을 입력해 주세요.')),
      );
      return;
    }

    final weatherSummary = _temperature != null
        ? '$_selectedCity ${_temperature!.toStringAsFixed(1)}°C (${_describeWeatherCode(_weatherCode)})'
        : _selectedCity;

    final response = await http.post(
      Uri.parse(_firestoreCollectionUrl),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${widget.idToken}',
      },
      body: jsonEncode({
        'fields': {
          'mood': {'stringValue': _selectedMood},
          'memo': {'stringValue': memo},
          'weather': {'stringValue': weatherSummary},
          'clientTime': {'stringValue': DateTime.now().toIso8601String()},
        }
      }),
    );

    if (response.statusCode == 401) {
      widget.onLogout();
      return;
    }

    if (response.statusCode == 200) {
      _memoController.clear();
      await _loadRecords();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('저장 실패 (${response.statusCode}): Firestore 규칙을 확인해 주세요.')),
      );
    }
  }

  Future<void> _deleteRecord(String docId) async {
    final response = await http.delete(
      Uri.parse('$_firestoreCollectionUrl/$docId'),
      headers: {'Authorization': 'Bearer ${widget.idToken}'},
    );

    if (response.statusCode == 200) {
      await _loadRecords();
    }
  }

  @override
  void dispose() {
    _latController.dispose();
    _lonController.dispose();
    _memoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('우리 동네 날씨 & 기분 기록장'),
        actions: [
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(widget.email, style: const TextStyle(fontSize: 13)),
            ),
          ),
          TextButton.icon(
            onPressed: widget.onLogout,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('로그아웃'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '1. 실시간 동네 날씨 조회 (Open-Meteo API)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _cityPresets.entries.map((entry) {
                          return ActionChip(
                            label: Text(entry.key),
                            onPressed: () {
                              setState(() {
                                _selectedCity = entry.key;
                                _latController.text = entry.value[0].toString();
                                _lonController.text = entry.value[1].toString();
                              });
                              _fetchWeather();
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _latController,
                              decoration: const InputDecoration(
                                labelText: '위도 (Latitude)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => _selectedCity = '사용자 지정 위치',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _lonController,
                              decoration: const InputDecoration(
                                labelText: '경도 (Longitude)',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onChanged: (_) => _selectedCity = '사용자 지정 위치',
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton.icon(
                            onPressed: _isWeatherLoading ? null : _fetchWeather,
                            icon: const Icon(Icons.refresh, size: 18),
                            label: const Text('조회'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (_isWeatherLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (_weatherError != null)
                        Text(_weatherError!, style: const TextStyle(color: Colors.red))
                      else if (_temperature != null)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.indigo.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$_selectedCity 현재 날씨',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _describeWeatherCode(_weatherCode),
                                    style: const TextStyle(fontSize: 18),
                                  ),
                                ],
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${_temperature!.toStringAsFixed(1)} °C',
                                    style: const TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.indigo,
                                    ),
                                  ),
                                  Text('풍속: ${_windSpeed?.toStringAsFixed(1)} km/h'),
                                ],
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '2. 오늘의 기분 기록하기',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: _moodOptions.map((mood) {
                          return ChoiceChip(
                            label: Text(mood),
                            selected: _selectedMood == mood,
                            onSelected: (_) => setState(() => _selectedMood = mood),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _memoController,
                              decoration: const InputDecoration(
                                hintText: '오늘 날씨와 함께 한 줄 기분을 남겨보세요',
                                border: OutlineInputBorder(),
                                isDense: true,
                              ),
                              onSubmitted: (_) => _saveRecord(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          FilledButton(
                            onPressed: _saveRecord,
                            child: const Text('저장'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Text(
                  '3. 내 기분 기록 목록 (Firestore 연동)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              if (_isRecordsLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_records.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: Text('아직 저장된 기록이 없습니다. 첫 기록을 남겨보세요!')),
                  ),
                )
              else
                ..._records.map((record) {
                  final timeStr = (record['clientTime'] ?? '').toString();
                  final formattedTime = timeStr.length >= 16
                      ? timeStr.substring(0, 16).replaceFirst('T', ' ')
                      : timeStr;
                  final moodEmoji = (record['mood'] ?? '😊').toString().split(' ').first;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        child: Text(moodEmoji, style: const TextStyle(fontSize: 20)),
                      ),
                      title: Text((record['memo'] ?? '').toString()),
                      subtitle: Text(
                        '${record['mood']} · ${record['weather']} · $formattedTime',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                        onPressed: () => _deleteRecord((record['id'] ?? '').toString()),
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}