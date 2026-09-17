"""Rebuild licensed reading selections from checked-in publisher XML, offline."""
from pathlib import Path
import xml.etree.ElementTree as E,json,re
ROOT=Path(__file__).parent

def text(e):return ' '.join(''.join(e.itertext()).split()) if e is not None else ''
def blocks(e):
 out=[]
 for child in e:
  if child.tag=='title':out.append('## '+text(child))
  elif child.tag=='p':out.append(text(child))
  elif child.tag=='sec':out.extend(blocks(child))
 return out
specs=[
 ('workplace','research','Abstract and introduction',[
 ('but its effectiveness is not clearly understood','Research gap','The opening narrows a broad trend to a specific uncertainty. It motivates the experiment instead of assuming that digital delivery improves learning.','structure'),
 ('Employees were randomly assigned to one of four conditions','Experimental comparison','Random assignment helps compare the learning conditions. Keep the four groups distinct when explaining the result.','comment'),
 ('20–35 hours','Measurement window','The test measured retention after roughly one day. This is not evidence of months-long retention or of improved job performance.','comment'),
 ('26% and 25% better respectively','Quantified result','These are relative differences reported by the authors, not percentage-point gains. “Respectively” maps the two values to the two interventions in the preceding order.','vocabulary')]),
 ('sleep','research','Abstract and introduction',[
 ('However, the effect of sleep on recognition memory is more equivocal.','Contrast and gap','“However” distinguishes recognition from recall. “Equivocal” means the evidence is ambiguous, not that there is definitely no effect.','vocabulary'),
 ('a 12-hour retention interval','Operational definition','The authors specify when memory was measured. A precise procedure lets readers evaluate what the experiment actually tested.','structure'),
 ('target-present lineup','Two different outcomes','The two experiments test correct identification and false identification separately. Avoid combining these outcomes into a single claim about better memory.','comment'),
 ('but had no effect on correct identifications','Qualified conclusion','The contrast limits the positive result. A useful model for reporting mixed findings without overstating them.','structure')]),
 ('structure','discursive','Overview and Rules 1–2',[
 ('Focus on a single message','Central claim','Use one main contribution to organise a paragraph or paper. Supporting ideas can be complex while still serving the same claim.','structure'),
 ('as simple as the data and logic can support but no simpler','Scope and evidence','The qualification prevents clarity from turning into oversimplification. This is guidance about scientific writing, not experimental evidence.','comment'),
 ('Define technical terms clearly','Reader knowledge','Make a term understandable before using it to carry an argument. In a classroom, ask the reader to paraphrase the definition.','vocabulary'),
 ('minimize the number of loose threads','Coherence','“Loose threads” is a metaphor for unresolved ideas the reader has to remember. Finish one line of reasoning before opening several others.','vocabulary')]),
 ('review','discursive','Rules 3 and 6',[
 ('while reading, to start writing down','Reading into writing','The recommendation joins note-taking and reading. Record both the source claim and your response so that a later draft is not a list of disconnected summaries.','structure'),
 ('use quotation marks','Attribution','Preserve the boundary between a source’s exact wording and your paraphrase. Keep a citation even when the final wording is your own.','comment'),
 ('Reviewing the literature is not stamp collecting.','A memorable contrast','The analogy rejects collecting references as an end in itself. The following sentence explains the analytical work a review must do.','structure'),
 ('identifies methodological problems','Critical synthesis','Compare how studies reached their conclusions, not only what they concluded. A method can limit how far a finding generalises.','comment')])]
manifest=[]
for name,kind,selection,notes in specs:
 r=E.parse(ROOT/'Sources'/f'{name}.xml').getroot();meta=r.find('./front/article-meta');secs=r.findall('./body/sec')
 title=text(meta.find('./title-group/article-title'))
 authors=', '.join((text(n.find('given-names'))+' '+text(n.find('surname'))).strip() for n in meta.findall("./contrib-group/contrib[@contrib-type='author']/name"))
 doi=text(meta.find("./article-id[@pub-id-type='doi']"));year=text(meta.find('./permissions/copyright-year'))
 licence=meta.find('./permissions/license');href=licence.get('{http://www.w3.org/1999/xlink}href','https://creativecommons.org/licenses/by/')
 assert 'Creative Commons Attribution License' in text(licence)
 if name in ('workplace','sleep'): content=['## Abstract']+blocks(meta.find('abstract'))+blocks(secs[0])
 elif name=='structure':content=blocks(secs[0])+sum([blocks(sec) for sec in secs[2].findall('sec')[:2]],[])
 else:content=blocks(secs[3])+blocks(secs[6])
 body='\n\n'.join(content)
 attribution=f'{authors} ({year}) · PLOS\n{selection}. Selected passages, not the complete paper.\nhttps://doi.org/{doi}\nCC BY · {href}\nOriginal wording retained; paragraph spacing and Markdown headings adapted. PPB margin notes are editorial teaching commentary, not statements by the authors. Reference numbers refer to the original paper.'
 annotations=[]
 sourcequote=next(p for p in content if not p.startswith('##'))[:80]
 for i,(quote,label,comment,k) in enumerate([(sourcequote,'Source & reuse',f'{authors} ({year}). {title}. DOI: {doi}\nCC BY: {href}\nSelection: {selection}. Layout adapted; teaching notes added by PPB. No endorsement implied.','comment')]+notes):
  start=body.index(quote);offset=len(body[:start].encode('utf-16-le'))//2
  annotations.append(dict(id=f'{name}-{i}',start=offset,end=offset+len(quote.encode('utf-16-le'))//2,quote=quote,kind=k,level='essay',label=label,body=comment,side='left' if i%2==0 else 'right',tag=['gray','blue','green','purple','orange'][i]))
 doc=dict(format='ielts-semantic-breakdown',version=1,document=dict(id='ppb-open-'+name,title=title,text=body,taskType=kind,prompt=attribution,language='en'),annotations=annotations)
 (ROOT/f'{name}.json').write_text(json.dumps(doc,ensure_ascii=False,indent=2)+'\n')
 manifest.append(dict(tags={'workplace':['Learning science','Workplace training'],'sleep':['Memory','Sleep','Psychology'],'structure':['Academic writing','Paper structure'],'review':['Literature reviews','Research methods']}[name],file=name+'.json',title=title,authors=authors,doi=doi,license=href,selection=selection,words=len(body.split())))
(ROOT/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n')
(ROOT/'LICENSES.md').write_text('# Open reading collection\n\nDownloaded from publisher XML on 17 September 2026. Article text belongs to the credited authors and is reused under the stated CC BY license. The collection contains selected passages, not full papers. Original wording and reference numbers are retained; Markdown headings and paragraph spacing are adapted. PPB teaching notes are additions, not author endorsements.\n\n'+'\n\n'.join(f"## {m['title']}\n{m['authors']}\n\nhttps://doi.org/{m['doi']}\n\nLicense: {m['license']}\n\nSelection: {m['selection']} ({m['words']} words)." for m in manifest))
print([(m['file'],m['words']) for m in manifest])
