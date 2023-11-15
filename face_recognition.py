from tensorflow.keras.models import load_model
from time import sleep
from tensorflow.keras.preprocessing.image import img_to_array
from tensorflow.keras.preprocessing import image
import cv2
import numpy as np

face_classifier=cv2.CascadeClassifier('opencv/data/haarcascades/haarcascade_frontalface_default.xml') #정면 얼굴 감지 모델
emotion_model = load_model('emotion_detection_model.h5') #감정 분석 모델
age_model = load_model('age_model.h5') #나이 분석 모델
gender_model = load_model('gender_model.h5') #성별 분석 모델

class_labels=['Angry','Disgust', 'Fear', 'Happy','Neutral','Sad','Surprise'] #감정 라벨
gender_labels = ['Male', 'Female'] #성별 라벨

cap=cv2.VideoCapture(0) 

face_detected = 0

while True:
    ret,frame=cap.read()
    labels=[]
    
    gray=cv2.cvtColor(frame,cv2.COLOR_BGR2GRAY)
    faces=face_classifier.detectMultiScale(gray,1.3,5) #얼굴 감지

    for (x,y,w,h) in faces: #얼굴 감지
        face_detected = 1
        cv2.rectangle(frame,(x,y),(x+w,y+h),(255,0,0),2) 
        roi_gray=gray[y:y+h,x:x+w]
        roi_gray=cv2.resize(roi_gray,(48,48),interpolation=cv2.INTER_AREA)

        roi=roi_gray.astype('float')/255.0  
        roi=img_to_array(roi)
        roi=np.expand_dims(roi,axis=0)  

        #감정 분석
        preds=emotion_model.predict(roi)[0]  
        emotion_label=class_labels[preds.argmax()]  
        label_position=(x,y)
        cv2.putText(frame,emotion_label,label_position,cv2.FONT_HERSHEY_SIMPLEX,1,(0,255,0),2)
        
        #성별 분석
        roi_color=frame[y:y+h,x:x+w]
        roi_color=cv2.resize(roi_color,(200,200),interpolation=cv2.INTER_AREA)
        gender_predict = gender_model.predict(np.array(roi_color).reshape(-1,200,200,3))
        gender_predict = (gender_predict>= 0.5).astype(int)[:,0]
        gender_label=gender_labels[gender_predict[0]] 
        gender_label_position=(x,y+h+50) 
        cv2.putText(frame,gender_label,gender_label_position,cv2.FONT_HERSHEY_SIMPLEX,1,(0,255,0),2)
        
        #나이 분석
        age_predict = age_model.predict(np.array(roi_color).reshape(-1,200,200,3))
        age_label = round(age_predict[0,0])
        age_label_position=(x+h,y+h)
        cv2.putText(frame,"Age="+str(age_label),age_label_position,cv2.FONT_HERSHEY_SIMPLEX,1,(0,255,0),2)
        
        print('emotion: ', emotion_label)
        print('gender: ', gender_label)
        print('age: ', age_label)
        
    cv2.imshow('Emotion Detector', frame)
    if cv2.waitKey(1) & 0xFF == ord('q'):
        break
cap.release()
cv2.destroyAllWindows()