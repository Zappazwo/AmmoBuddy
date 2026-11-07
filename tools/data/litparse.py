"""Data-only parsers: Lua table literals and SQL VALUES tuples. Nothing is executed."""
import re

NUM = re.compile(r'-?\d+(\.\d+)?([eE][-+]?\d+)?')


class LuaLit:
    def __init__(self, s):
        self.s, self.i = s, 0

    def ws(self):
        s = self.s
        while self.i < len(s):
            c = s[self.i]
            if c in ' \t\r\n':
                self.i += 1
            elif s.startswith('--', self.i):
                j = s.find('\n', self.i)
                self.i = len(s) if j < 0 else j
            else:
                break

    def value(self):
        self.ws()
        s = self.s
        c = s[self.i]
        if c == '{':
            return self.table()
        if c in '\'"':
            return self.string()
        m = NUM.match(s, self.i)
        if m:
            self.i = m.end()
            t = m.group(0)
            return float(t) if ('.' in t or 'e' in t.lower()) else int(t)
        for w, v in (('nil', None), ('true', True), ('false', False)):
            if s.startswith(w, self.i):
                self.i += len(w)
                return v
        raise ValueError('unexpected %r at %d' % (s[self.i:self.i + 30], self.i))

    def string(self):
        q = self.s[self.i]
        self.i += 1
        out = []
        while True:
            c = self.s[self.i]
            if c == '\\':
                n = self.s[self.i + 1]
                out.append({'n': '\n', 't': '\t'}.get(n, n))
                self.i += 2
            elif c == q:
                self.i += 1
                return ''.join(out)
            else:
                out.append(c)
                self.i += 1

    def table(self):
        self.i += 1
        d, n = {}, 0
        while True:
            self.ws()
            if self.s[self.i] == '}':
                self.i += 1
                break
            if self.s[self.i] == '[':
                self.i += 1
                k = self.value()
                self.ws()
                assert self.s[self.i] == ']'
                self.i += 1
                self.ws()
                assert self.s[self.i] == '='
                self.i += 1
                d[k] = self.value()
            else:
                n += 1
                d[n] = self.value()
            self.ws()
            if self.s[self.i] in ',;':
                self.i += 1
        return d


def lua_block(path, var):
    s = open(path, encoding='utf-8').read()
    m = re.search(re.escape(var) + r'\s*=\s*\[\[return\s*(\{.*?\n\})\]\]', s, re.S)
    return LuaLit(m.group(1)).table()


def seq(t):
    """Lua array-like dict {1:..,2:..} -> list (missing indices -> None)."""
    if not isinstance(t, dict):
        return t
    n = max([k for k in t if isinstance(k, int)] or [0])
    return [t.get(i) for i in range(1, n + 1)]


def sql_rows(line):
    """Parse 'INSERT INTO `x` VALUES (...),(...);' into lists of values."""
    s = line[line.index('VALUES') + 6:]
    i = 0
    rows = []
    while True:
        i = s.find('(', i)
        if i < 0:
            break
        i += 1
        row = []
        cur = ''
        while True:
            c = s[i]
            if c == "'":
                i += 1
                buf = []
                while True:
                    c = s[i]
                    if c == '\\':
                        buf.append(s[i + 1])
                        i += 2
                    elif c == "'" and s[i + 1:i + 2] == "'":
                        buf.append("'")
                        i += 2
                    elif c == "'":
                        i += 1
                        break
                    else:
                        buf.append(c)
                        i += 1
                row.append(''.join(buf))
                cur = None
            elif c in ',)':
                if cur is not None:
                    t = cur.strip()
                    row.append(None if t == 'NULL' else (float(t) if ('.' in t or 'e' in t) else int(t)))
                cur = ''
                i += 1
                if c == ')':
                    break
            else:
                cur += c
                i += 1
        rows.append(row)
    return rows
