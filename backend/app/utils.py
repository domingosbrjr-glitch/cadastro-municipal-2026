import re
def normalize_cpf(cpf: str) -> str:
    return re.sub(r"\D", "", cpf or "")

def is_valid_cpf(cpf: str) -> bool:
    cpf = normalize_cpf(cpf)
    if len(cpf) != 11:
        return False
    if cpf == cpf[0] * 11:
        return False

    def calc(part: str) -> str:
        s = 0
        for i, ch in enumerate(part):
            s += int(ch) * (len(part) + 1 - i)
        d = (s * 10) % 11
        return "0" if d == 10 else str(d)

    d1 = calc(cpf[:9])
    d2 = calc(cpf[:9] + d1)
    return cpf[-2:] == d1 + d2
