from pathlib import Path
lines = Path('/home/bonobo/antivenom/philosophy/appendices/appendix-a.tex').read_text().splitlines()
sections=[]
for i,l in enumerate(lines):
    if l.startswith('\\section{'):
        sections.append((i,l[len('\\section{'):-1]))
for si,(start,title) in enumerate(sections):
    end = sections[si+1][0] if si+1 < len(sections) else len(lines)
    print(f'## {title} ({start+1}-{end})')
    idx=0
    j=start
    while j<end:
        s=lines[j].strip()
        if s=='\\[':
            k=j+1
            while k<end and lines[k].strip()!='\\]':
                k+=1
            idx+=1
            first=' '.join(lines[j+1:min(j+3,k)]).strip()
            print(f'  [{idx}] lines {j+1}-{k+1}: {first[:120]}')
            j=k+1
        else:
            j+=1
