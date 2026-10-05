import subprocess,time,os
h=os.environ.get('HDC','/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc')
target=os.environ['HDC_TARGET']
def run(*a):return subprocess.run([h,'-t',target,*a],capture_output=True,text=True).stdout
print(run('shell','uitest','uiInput','click','1460','178'));time.sleep(.7)
print(run('shell','hitrace','--trace_begin','-b','65536','ace','graphic'))
for i in range(3):
 print(run('shell','uitest','uiInput','click','1310','1730'));time.sleep(.65)
 open('/tmp/v63-entry-'+str(i)+'.fps','w').write(run('shell','hidumper','-s','10','-a','composer fps'))
 print(run('shell','uitest','uiInput','click','1460','178'));time.sleep(.65)
 open('/tmp/v63-exit-'+str(i)+'.fps','w').write(run('shell','hidumper','-s','10','-a','composer fps'))
print(run('shell','hitrace','--trace_finish','-o','/data/local/tmp/v63.trace'))
print(run('file','recv','/data/local/tmp/v63.trace','/tmp/v63.trace'))
