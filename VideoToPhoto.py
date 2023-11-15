import cv2
video_path = "444.mp4"  # 替换为您的视频文件路径
cap = cv2.VideoCapture(video_path)
frame_count = 0  # 用于计数帧数
while cap.isOpened():
    ret, frame = cap.read()
    if not ret:
        break

    # 在这里可以对每一帧进行处理（如果需要）

    # 保存图像
    image_path = f"frame_{frame_count}.jpg"  # 图像保存路径和文件名
    cv2.imwrite(image_path, frame)

    frame_count += 1

cap.release()  # 释放视频文件