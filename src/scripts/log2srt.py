import sys,re,os
import numpy as np

#res=[]
#tstamps=[]
#lab=[]
#fn=''
#acids=np.zeros(4)
counter=1

def convert_milliseconds(milliseconds):

    # Calculate total seconds
    total_seconds = milliseconds // 1000

    # Calculate remaining milliseconds
    remaining_milliseconds = milliseconds % 1000

    # Calculate hours, minutes, and seconds
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)

    tstamp="{0:02d}:{1:02d}:{2:02d},{3:03d}".format(hours,minutes,seconds,remaining_milliseconds)

    return tstamp

def print_word(c,b,e,w,cnf):

    begin=convert_milliseconds(int(b))
    end=convert_milliseconds(int(e))
    #tstamp="{0}\n{1} --> {2}\n{3} {4:0.3f}\n".format(c, begin, end, w, cnf)
    tstamp="{0}\n{1} --> {2}\n{3}\n".format(c, begin, end, w, cnf)

    print(tstamp,end='\n',flush=True)
    return tstamp

'''Main loop'''
if __name__ == "__main__":

    if len(sys.argv) < 1:
        print(f'Usage: {sys.argv[0]} log_file')
        raise SystemExit()

log_file=sys.argv[1]

with open(log_file, 'r') as file:
    # Read the file line by line


    for lx in file:

        if lx=='': break

        l=lx.strip().split(' ')
        if ':' in l[0]:
            l.pop(0)

        if l[0]=='File': # Flush previous if any

            counter=1
            word=''
            wbegin=''
            wend=''
            wconf=0
            sw=0
            dur=0

            fn=l[1].split('.')[:-1][0]
            print(fn)
            f=open(fn + '.srt','w',encoding='utf-8')

        elif 'Result' in l[0]: # full Result line
            l = [l[0],l[1]+']',l[3],l[4]] #re-arange
            lbegin=l[1].replace('[','').split('-')[0]
            lend=l[1].replace(']','').split('-')[1]
            label=l[2]
            confidence=float(l[3][1:-1])

            if label[-1]=='#' and label[0]!='#':
                wbegin=lbegin
                word=word+label.replace('#','')
                dur=float(lend)-float(lbegin)
                wconf+=confidence/dur
                sw+=1
            elif label[-1]=='#' and label[0]=='#':
                word=word+label.replace('#','')
                dur=float(lend)-float(lbegin)
                wconf+=confidence/dur
                sw+=1
            elif label[-1]!='#' and label[0]=='#':
                wend=lend
                word=word+label.replace('#','')
                dur=float(lend)-float(lbegin)
                wconf+=confidence/dur
                sw+=1
                fdur=(float(wend)-float(wbegin))/1000
                out=print_word(counter,wbegin,wend,word,wconf/fdur)
                f.write(out+'\n')
                word=''
                wbegin=''
                wend=''
                counter+=1
                wconf=0
                sw=0
            else:
                out=print_word(counter,lbegin,lend,label,confidence)
                f.write(out+'\n')
                word=''
                wbegin=''
                wend=''
                counter+=1
                wconf=0
                sw=0
        else:
            print(lx,end='',flush=True)

#sentence = ' '.join(res)
#sentence=sentence.replace('# #','')
#sentence=sentence.replace('#','')
#print('Result:')
#print(sentence,end='',flush=True)