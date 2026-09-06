from pathlib import Path
text = Path('/home/bonobo/antivenom/philosophy/appendices/appendix-a.tex').read_text()
lines = text.splitlines()
sections=[]
for i,l in enumerate(lines, start=1):
    if l.startswith('\\section{'):
        title=l[len('\\section{'):-1]
        sections.append((i,title))
for idx,(line,title) in enumerate(sections):
    end=sections[idx+1][0]-1 if idx+1<len(sections) else len(lines)
    first_eq=None
    for j in range(line,end+1):
        if lines[j-1].strip()=='\\[' or lines[j-1].startswith('\\begin{equation') or lines[j-1].startswith('\\begin{align'):
            k=j
            if lines[j-1].strip()=='\\[':
                while k<=end and lines[k-1].strip()!='\\]':
                    k+=1
            else:
                env=lines[j-1].strip()[len('\\begin{'):].split('}')[0]
                while k<=end and lines[k-1].strip()!=f'\\end{{{env}}}':
                    k+=1
            eq=' '.join(x.strip() for x in lines[j-1:k])
            first_eq=(j,k,eq)
            break
    print(f'{line}: {title}')
    if first_eq:
        j,k,eq=first_eq
        print(f'  eq {j}-{k}: {eq[:180]}')
    else:
        print('  no eq')
