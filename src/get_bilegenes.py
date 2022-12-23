#!/usr/bin/env python

import urllib.request as ur
from bs4 import BeautifulSoup as bs
import sys
import re
import time

def main():
    args = sys.argv
    pathway_id = str(args[1])
    #pathway_id = 'ko00121'
    orthology_ids = get_orthology_ids(pathway_id)
    print(orthology_ids)

    print('Found {} orthology ids for pathway "{}"' .format(len(orthology_ids), pathway_id))

    if not orthology_ids:
        sys.exit(1)

    for orthology_id in orthology_ids:
        gene_ids = get_gene_ids(orthology_id)

        print('Writing {} FASTA gene sequences to "{}.fa"' .format(len(gene_ids), orthology_id))

        with open('BA_genes/'+orthology_id + '.fa', 'w') as out:
            for i, gene_id in enumerate(gene_ids, 1):
                sys.stdout.write('.')
                if not i % 5:
                    sys.stdout.write(' ')
                if not i % 20:
                    sys.stdout.write('\n')
                    time.sleep(30)
                sys.stdout.flush()
                fasta = get_fasta(gene_id)
                out.write(fasta)

        print("done")



def get_ids(url):
    response = ur.urlopen(url)
    #html = response.read(features='html.parser')
    #b = bs(html)
    b = bs(response, 'html.parser')
    links = b.find_all(href=re.compile('entry/'))
    return [link.text for link in links]


def get_orthology_ids(pathway_id):
    URL = 'http://www.genome.jp'
    FUN = '/dbget-bin/get_linkdb?-t+orthology+pathway:'
    return get_ids(URL + FUN + pathway_id)


def get_gene_ids(orthology_id):
    URL = 'http://www.genome.jp'
    FUN = '/dbget-bin/get_linkdb?-t+genes+ko:'
    return get_ids(URL + FUN + orthology_id)


def get_fasta(gene_id):
    URL = 'http://www.genome.jp'
    FUN = '/dbget-bin/www_bget?'
    response = ur.urlopen(URL + FUN + gene_id)
    html = bs(response, 'html.parser')
    AA_seqtag=html.find('button',text=re.compile('AA seq'))
    AA_link=AA_seqtag['onclick']
    AA_link=URL+re.search(r"'(.*?)'",AA_link).group(1)
    AA_seq=ur.urlopen(AA_link)
    AA_seq=bs(AA_seq, 'html.parser')
    return AA_seq.pre.text


if __name__ == '__main__':
    main()
