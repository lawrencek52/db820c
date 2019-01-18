from __future__ import division
import cv2
import numpy as np
from math import cos, sin

green = (0, 255, 0)

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
	#scale the image
	max_dimension = max(image.shape)
	scale = 700/max_dimension
	image = cv2.resize(image, None, fx=scale, fy=scale)
	# clean the image
	image_blur = cv2.GaussianBlur(image, (7,7), 0)
	image_blur_hsv = cv2.cvtColor(image_blur, cv2.COLOR_RGB2HSV)
	# define filters
	# filter by the color (red)
	min_red = np.array([10,100, 80])
	max_red = np.array([10, 256, 256])
	mask1 = cv2.inRange(image_blur_hsv, min_red, max_red)
	# brightness
	min_red2 = np.array([170,100, 80])
	max_red2 = np.array([180, 256, 256])
	mask2 = cv2.inRange(image_blur_hsv, min_red2, max_red2)
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
	circled = circle_contour(overlay, big_strawberry_contour)
	show(circled)
	# convert image back to original color scheme
	bgr = cv2.cvtColor(overlay, cv2.COLOR_RGB2BGR)
	return bgr

#read the image
image = cv2.imread('berry.jpg')
result = find_strawberry(image)
cv2.imwrite('berry2.jpg', result)

