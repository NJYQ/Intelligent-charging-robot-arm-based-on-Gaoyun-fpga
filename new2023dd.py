import sys
sys.path.append('/pys')
import serial
import time
import cv2
import cv2.aruco as aruco

ser=serial.Serial('/dev/ttyS1',115200,timeout=0.5)#这个是机械臂串口，串口有变化，根据dev文件夹下面的更改
time.sleep(3)
serGHT=serial.Serial('/dev/ttyS2',115200,timeout=0.5)#这个是广和通串口，有变化，根据dev文件夹下面的更改
time.sleep(3)

#下面的部分是=+初始化+=链接到云平台的，根据你写的广合通进行修改
##############################################################################
serGHT.write('AT\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+MIPCALL?\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+MIPCALL=1\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+MIPCALL?\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+TCDEVINFOSET=1,"QAXN18V0KU","L610","pKA3acBG49CWPVINdwxF0Q=="\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+TCMQTTCONN=1,20000,240,1,1\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+TCMQTTSUB="$thing/down/property/QAXN18V0KU/L610",1\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+TCMQTTPUB="$thing/up/property/QAXN18V0KU/L610",1,"{\"method\":\"report\",\"clientToken\":\"123\",\"params\":{\"power_switch\":0}}"\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+TCMQTTPUB="$thing/up/property/QAXN18V0KU/L610",1,"{\"method\":\"report\",\"clientToken\":\"123\",\"params\":{\"wendu\":28}}"\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+TCMQTTPUB="$thing/up/property/QAXN18V0KU/L610",1,"{\"method\":\"report\",\"clientToken\":\"123\",\"params\":{\"zuobiao\":20.20}}"\r\n'.encode('utf-8'))
time.sleep(0.3)

serGHT.write('AT+TCMQTTPUB="$thing/up/property/QAXN18V0KU/L610",1,"{\"method\":\"report\",\"clientToken\":\"123\",\"params\":{\"dianya\":3.3}}"\r\n'.encode('utf-8'))
time.sleep(0.3)

#**********************************************************************************************


##############################################################################
#是=+初始化+=结束
font=cv2.FONT_HERSHEY_SIMPLEX

ser.write('{#000P0800T1000!}'.encode('utf-8'))
time.sleep(1.4)

ser.write('$KMS:0,60,230,1000!'.encode('utf-8'))
time.sleep(1.4)


#下面是打开摄像头
###############################################################face
cap=cv2.VideoCapture(1)
cap.set(3,640)
cap.set(4,480)
arcuoMtime = 0

while (arcuoMtime <4000):
         retqq,frame = cap.read()
         #frame=cv2.flip(frame,0)
         gray = cv2.cvtColor(frame, cv2.COLOR_BGR2GRAY)
         aruco_dict = aruco.Dictionary_get(aruco.DICT_4X4_250)
         parameters = aruco.DetectorParameters_create()
         corners, ids, rejectedImgPoints = aruco.detectMarkers(gray, aruco_dict, parameters=parameters)
         aruco.drawDetectedMarkers(frame, corners,ids)
         #print(ids)
         cv2.namedWindow('frame',0)
         cv2.resizeWindow('frame',450,450)
         cv2.putText(frame, "QRcodeScan",(10,30),font,1,(255,0,0),2)
         cv2.imshow("frame", frame)
         if ids!=None:
             cv2.putText(frame, "SUCCESS",(50,50),font,1,(255,255,0),3) 
             cv2.imshow("frame", frame)
             cv2.waitKey(1000)
             break
         cv2.waitKey(1)
         arcuoMtime = arcuoMtime +1
###############################################################

###连接腾讯云 显示开始充电
serGHT.write('AT\r\n'.encode('utf-8'))
serGHT.flush()

serGHT.write('AT+CPIN?\r\n'.encode('utf-8'))
serGHT.flush()

serGHT.write('AT+CSQ\r\n'.encode('utf-8'))
serGHT.flush()

serGHT.write('AT+CGREG?\r\n'.encode('utf-8'))
serGHT.flush()

serGHT.write('AT+MIPCALL?\r\n'.encode('utf-8'))
serGHT.flush()

serGHT.write('AT+MIPCALL=1\r\n'.encode('utf-8'))
serGHT.flush()

serGHT.write('AT+MIPCALL?\r\n'.encode('utf-8'))
serGHT.flush()

serGHT.write('AT+TCDEVINFOSET=1,"QAXN18V0KU","L610","pKA3acBG49CWPVINdwxF0Q=="\r\n'.encode('utf-8'))
serGHT.flush()
serGHT.write('AT+TCMQTTCONN=1,20000,240,1,1\r\n'.encode('utf-8'))
serGHT.flush()
serGHT.write('AT+TCMQTTSUB="$thing/down/property/QAXN18V0KU/L610",1\r\n'.encode('utf-8'))
serGHT.flush()
serGHT.write('AT+TCDEVINFOSET=1,"QAXN18V0KU","L610","pKA3acBG49CWPVINdwxF0Q=="\r\n'.encode('utf-8'))
serGHT.flush()
serGHT.write('AT+TCMQTTCONN=1,20000,240,1,1\r\n'.encode('utf-8'))
serGHT.flush()
serGHT.write('AT+TCMQTTSUB="$thing/down/property/QAXN18V0KU/L610",1\r\n'.encode('utf-8'))
serGHT.flush()
time.sleep(3)
#按钮变化
serGHT.write('AT+TCMQTTPUB="$thing/up/property/QAXN18V0KU/L610",1,"{\\"method\\":\\"report\\",\\"clientToken\\":\\"123\\",\\"params\\":{\\"power_switch\\":1}}"\r\n'.encode('utf-8'))
serGHT.flush()
time.sleep(2)

#识别人脸或者其他的充电口
###############################################################face
zzzzz=1500
xx=0
yy=110
zz=200

xz0=1500

sersend_switch=0

face_cascade = cv2.CascadeClassifier("cascade5.xml")
#mouth_cascade = cv2.CascadeClassifier("cascade.xml")
time.sleep(1)
ser.write('$KMS:0,110,200,2000!'.encode('utf-8'))
time.sleep(2)
timesss=0

breakcode = 0
while (breakcode == 0):
   res,img=cap.read()
   #img=cv2.flip(img,0) 
   if res:
      gray = cv2.cvtColor(img,cv2.COLOR_BGR2GRAY)

      # 探测图片中的人脸

      faces = face_cascade.detectMultiScale(

      gray,

      scaleFactor = 1.2,

      minNeighbors = 2,

      minSize = (10,10),

      flags = cv2.CASCADE_SCALE_IMAGE

      )

      print(faces)
      for(x,y,w,h) in faces:
          
          if timesss<80 :
                strn1 = "$KMS:"
                strn2 = ","
                strn3 = "100!"
                if (sersend_switch == 0):
                         if (y+h/2)<220:
                            zz=zz+int(abs((y+h/2)-240)/10)
                            if(zz>500):
                               zz=500
                         if (y+h/2)>260:
                            zz=zz-int(abs((y+h/2)-240)/10)
                            if(zz<100):
                               zz=100


                if (sersend_switch == 1):      
                         if (x+w/2)<310:
                            xz0=xz0+int(abs((x+w/2)-320)/11)
                         if (x+w/2)>330:
                            xz0=xz0-int(abs((x+w/2)-320)/11)
                   
                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                sendsern_dibu="{#000P"+str(xz0)+"T0500!}"

                if ( int(abs((y+h/2)-240))>10   or  int(abs((x+w/2)-360))>12 ):
                         if (sersend_switch == 0):
                                 ser.write(sendsern.encode('utf-8'))
                         print(sendsern_dibu)
                         if (sersend_switch == 1):
                                 ser.write(sendsern_dibu.encode('utf-8'))
                         if (sersend_switch == 0):
                                 sersend_switch = 1
                         else :
                                 sersend_switch = 0


          timesss=timesss+1

          print(timesss)

          if timesss>80 :
                strn1 = "$KMS:"
                strn2 = ","
                strn3 = "400!"
                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                zz=zz+30
                ser.write(sendsern.encode('utf-8'))
                time.sleep(0.5)
                yy=yy+30
                #zz=zz+5
                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                ser.write(sendsern.encode('utf-8'))          
                time.sleep(0.5)
                yy=yy+30
                #zz=zz+5
                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                ser.write(sendsern.encode('utf-8'))          
                time.sleep(0.5)
                yy=yy+20
                #zz=zz+5
                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                ser.write(sendsern.encode('utf-8'))          
                time.sleep(0.5)
                yy=yy+20
                #zz=zz+5
                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                ser.write(sendsern.encode('utf-8'))          
                time.sleep(0.5)
                yy=yy+20
                #zz=zz+5
                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                ser.write(sendsern.encode('utf-8'))          
                time.sleep(0.5)
                yy=yy+10

                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                ser.write(sendsern.encode('utf-8'))          
                time.sleep(0.5)
                yy=yy+5

                sendsern=strn1+str(xx)+strn2+str(yy)+strn2+str(zz)+strn2+strn3
                ser.write(sendsern.encode('utf-8'))          
                time.sleep(2)

                breakcode = 1

          cv2.rectangle(img,(x,y),(x+w,y+h),(0,255,0),2)
          

      cv2.imshow('frame',img)
      cv2.waitKey(200)

ser.write('$KMS:0,110,200,2000!'.encode('utf-8'))

#go back
"""
time.sleep(6)
ser.write('{#000P1500T1000!}'.encode('utf-8'))
time.sleep(2)
ser.write('{#001P1500T1000!}'.encode('utf-8'))
time.sleep(2)
ser.write('{#002P1500T1000!}'.encode('utf-8'))
time.sleep(2)
ser.write('{#003P1500T1000!}'.encode('utf-8'))
time.sleep(2)
ser.write('{#004P1500T1000!}'.encode('utf-8'))
time.sleep(2)
"""
