import subprocess,time
import os
h=os.environ.get('HDC','/Applications/DevEco-Studio.app/Contents/sdk/default/openharmony/toolchains/hdc');t=os.environ['HDC_TARGET']
def r(*a):return subprocess.run([h,'-t',t,*a],capture_output=True,text=True,errors='replace').stdout
print(r('shell','uitest','uiInput','keyEvent','Home') if os.environ.get('FRIDGE_RESUME') else r('shell','aa','force-stop','com.fridgewidget.app'),flush=True)
print(r('shell','hitrace','--trace_begin','-b','65536','ace','graphic','app'),flush=True)
print(r('shell','aa','start','-a','EntryAbility','-b','com.fridgewidget.app'),flush=True)
time.sleep(3)
open('/tmp/v64-launch.fps','w').write(r('shell','hidumper','-s','10','-a','composer fps'))
print(r('shell','hitrace','--trace_finish','-o','/data/local/tmp/v64-launch.trace'),flush=True)
print(r('file','recv','/data/local/tmp/v64-launch.trace','/tmp/v64-launch.trace'),flush=True)
open('/tmp/v64-launch.log','w').write(r('shell','hilog','-x'))
