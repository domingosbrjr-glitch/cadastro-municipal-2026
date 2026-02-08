String normalizeCpf(String cpf) => cpf.replaceAll(RegExp(r'\D'), '');

bool isValidCpf(String cpf) {
  cpf = normalizeCpf(cpf);
  if (cpf.length != 11) return false;
  if (RegExp(r'^(\d)\1{10}\$').hasMatch(cpf)) return false;

  int calc(String part) {
    int sum = 0;
    for (int i = 0; i < part.length; i++) {
      sum += int.parse(part[i]) * (part.length + 1 - i);
    }
    int d = (sum * 10) % 11;
    return d == 10 ? 0 : d;
  }

  final d1 = calc(cpf.substring(0, 9));
  final d2 = calc(cpf.substring(0, 9) + d1.toString());
  return cpf.substring(9) == "$d1$d2";
}
