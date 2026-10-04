import subprocess,time,sys
import os
h=os.environ.get('HDC','/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc')
def run(*a):return subprocess.run([h,*a],capture_output=True,text=True).stdout
label=sys.argv[1];run('shell','hitrace','--trace_begin','-b','65536','ace','graphic')
for i in range(3):
 run('shell','uitest','uiInput','click','2260','404');time.sleep(.55)
 open('/tmp/'+label+'-entry-'+str(i)+'.fps','w').write(run('shell','hidumper','-s','10','-a','composer fps'))
 run('shell','uitest','uiInput','click','2400','180');time.sleep(.55)
 open('/tmp/'+label+'-exit-'+str(i)+'.fps','w').write(run('shell','hidumper','-s','10','-a','composer fps'))
print(run('shell','hitrace','--trace_finish','-o','/data/local/tmp/'+label+'.trace'))
print(run('file','recv','/data/local/tmp/'+label+'.trace','/tmp/'+label+'.trace'))
