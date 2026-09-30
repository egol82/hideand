#!/usr/bin/env python3
"""Offline mono reference soundtrack from exact synthesized PCM and capture-event timestamps.
This is not an audio device recording, binaural mix, or a measurement of playback latency.
"""
from __future__ import annotations
from array import array
from pathlib import Path
import json, math, sys, wave
ROOT=Path(__file__).resolve().parents[1]/'ci-artifacts'
def main():
    doc=json.loads((ROOT/'feel18-audio-events.json').read_text(encoding='utf-8'))
    rate=int(doc['rate']);n=round(doc['frames']/doc['fps']*rate);mix=array('f',[0])*n
    for event in doc['events']:
        name=f"{event['key']}_{event['variant']}_{int(event['muffled'])}.wav"
        with wave.open(str(ROOT/'feel18-audio'/name),'rb') as w:
            if (w.getframerate(),w.getnchannels(),w.getsampwidth())!=(rate,1,2):raise ValueError('Unexpected PCM format')
            samples=array('h',w.readframes(w.getnframes()))
        if sys.byteorder!='little':samples.byteswap()
        start=round(float(event['time'])*rate);gain=float(event['gain'])*0.60
        for i,v in enumerate(samples):
            if 0<=start+i<n:mix[start+i]+=v/32768*gain
    peak=max((abs(v) for v in mix),default=0)
    if not math.isfinite(peak) or peak==0:raise ValueError('Empty/nonfinite preview')
    gain=min(1,0.85/peak)
    out=array('h',(round(v*gain*32767) for v in mix))
    if sys.byteorder!='little':out.byteswap()
    with wave.open(str(ROOT/'feel18_preview.wav'),'wb') as w:w.setparams((1,2,rate,n,'NONE','not compressed'));w.writeframes(out.tobytes())
    (ROOT/'feel18-audio-report.json').write_text(json.dumps({'events':len(doc['events']),'duration_seconds':n/rate,'peak_before_safety_gain':peak,'safety_gain':gain,'note':doc['note']},indent=2)+'\n')
    print('FEEL18_AUDIO_PREVIEW_PASS',len(doc['events']),n/rate,peak)
if __name__=='__main__':main()
