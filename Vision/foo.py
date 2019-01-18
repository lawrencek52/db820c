#from __future__ import division
import cv2
import time
import numpy as np
#from math import cos, sin
#
#
# This demo captures frames from the camera and runs the berry program. 
# it is a little slow on the 410c (several frames per second) but it at
# least demonstrates OpenCV processing images
#
# This demo is not using all 4 cores, it only uses a single core. 
#     Need to rewrite so it runs in multiple cores.
# If no RED area is found the programm crashes.
#     Need to add error checking.
#
green = (0, 255, 0)
cap = cv2.VideoCapture(0)
cap.set(cv2.CAP_PROP_FRAME_WIDTH, 320)
cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 240)
time.sleep(2)
#cap.set(cv2.CAP_PROP_EXPOSURE,-4.0)

# define filters
# filter by the color (red)
min_red = np.array([10,100, 80])
max_red = np.array([10, 256, 256])
# brightness
min_bright = np.array([170,100, 80])
max_bright = np.array([180, 256, 256])


def show(image):
	# figure size in inches
	cv2.imshow('image',image)
	cv2.waitKey(0)
	cv2.destroyAllWindows()


def overlay_mask(mask, image):
	# mask the rgb
	rgb_mask = cv2.cvtColor(mask, cv2.COLOR_GRAY2RGB)
	img = cv2.addWeighted(rgb_mask, 0.5, image, 0.5, 0)
	return img

def find_biggest_contour(image):
    #copy image so we can modify it
    image = image.copy()
    contours, hierarchy = cv2.findContours(image, cv2.RETR_LIST, cv2.CHAIN_APPROX_SIMPLE)[-2:]
    # isolate the largest contour
    contour_sizes =[(cv2.contourArea(contour), contour) for contour in contours]
    biggest_contour = max(contour_sizes, key=lambda x: x[0])[1]
    #return the biggest contour
    mask = np.zeros(image.shape, np.uint8)
    cv2.drawContours(mask, [biggest_contour], -1, 255, -1)
    return biggest_contour, mask

def circle_contour(image, contour):
	# bounding Ellipse
	image_with_ellipse =image.copy()
	ellipse = cv2.fitEllipse(contour)
	#add it
	cv2.ellipse(image_with_ellipse, ellipse, green, 2, cv2.LINE_AA)
	return image_with_ellipse
	
	
def find_strawberry(image):
	# convert to the correct color scheme
	image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
	# clean the image
	image_blur = cv2.GaussianBlur(image, (5,5), 0)
	image_blur_hsv = cv2.cvtColor(image_blur, cv2.COLOR_RGB2HSV)
	# mask the image using the filters we predefined
	mask1 = cv2.inRange(image_blur_hsv, min_red, max_red)
	mask2 = cv2.inRange(image_blur_hsv, min_bright, max_bright)
	mask = mask1 + mask2
	# segment the image
	kernel= cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15,15))
	mask_closed = cv2.morphologyEx(mask, cv2.MORPH_CLOSE, kernel)
	mask_clean =cv2.morphologyEx(mask_closed, cv2.MORPH_OPEN, kernel)
	#find the biggest strawberry
	big_strawberry_contour, mask_strawberries = find_biggest_contour(mask_clean)
	# overlay the mask we created onto the image
	overlay = overlay_mask(mask_clean, image)
	#circle the biggest strawberry
#	circled = circle_contour(overlay, big_strawberry_contour)
	# convert image back to original color scheme
#	bgr = cv2.cvtColor(circled, cv2.COLOR_RGB2BGR)
	bgr = cv2.cvtColor(overlay, cv2.COLOR_RGB2BGR)
	return bgr

#read the image
while(True):
    ret, image = cap.read()
    #show(image)
    result = find_strawberry(image)
    # display the result
    cv2.imshow('frame', result)
    # loop until we get a Q key
    if cv2.waitKey(1) & 0xFF == ord('q'):
       break;

#when we are all done cleanup
cap.release()
cv2.destroyAllWindows()

