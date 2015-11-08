package com.naver.android.pholar.util.imagestabilizer;

import android.graphics.Bitmap;

import org.opencv.android.OpenCVLoader;
import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.KeyPoint;
import org.opencv.core.Mat;
import org.opencv.core.MatOfKeyPoint;
import org.opencv.features2d.DescriptorExtractor;
import org.opencv.features2d.FeatureDetector;
import org.opencv.imgproc.Imgproc;

import java.util.ArrayList;

/**
 * Created by eunchuljeon on 2015. 11. 8..
 */
public class ImageStabilizer {
    static {
        if (!OpenCVLoader.initDebug()) {
            // Handle initialization error
        } else {
            System.loadLibrary("ImageStabilizer");
        }
    }

    public native int getGrayImages(long[] orignalMats, long[] resultMats, int numOfImages);
    public native int getFeatrueExtractedImages(long[] orignalMats, long[] resultMats, int numOfImages);
    public native int getMatchedFeatureImages(long[] orignalMats, long[] resultMats, int numOfImages);
    public native int getStabilizedImages(long[] originalMats, long[] resultMats, int numOfImages);

    public ArrayList<Bitmap> featureExtraction(ArrayList<Bitmap> originals){
        ArrayList<Bitmap> results = new ArrayList<Bitmap>();
        ArrayList<Mat> originalMats = new ArrayList<Mat>();
        ArrayList<Mat> resultMats = new ArrayList<Mat>();

        int numOfImages = originals.size();

        long originalMatAddrs[] = new long[numOfImages];
        long resultMatAddrs[] = new long[numOfImages];

        for( int i =0; i < numOfImages; i++) {
            Bitmap bmp = originals.get(i);
            Mat originalMat = new Mat(bmp.getHeight(), bmp.getWidth(), CvType.CV_8UC4);
            Utils.bitmapToMat(bmp, originalMat);
            originalMats.add(originalMat);
            originalMatAddrs[i] = originalMat.getNativeObjAddr();

            Mat resultMat = new Mat(bmp.getHeight(), bmp.getWidth(), CvType.CV_8UC4);
            resultMats.add(resultMat);
            resultMatAddrs[i] = resultMat.getNativeObjAddr();
        }

        getFeatrueExtractedImages(originalMatAddrs, resultMatAddrs, numOfImages);

        for( int i =0 ; i < numOfImages; i++){
            Mat resultMat = resultMats.get(i);
            Bitmap bmp2 = Bitmap.createBitmap(resultMat.cols(), resultMat.rows(), Bitmap.Config.ARGB_8888);
            Utils.matToBitmap(resultMat, bmp2);
            results.add(bmp2);
        }
        return results;
    }

    public ArrayList<Bitmap> featureMatching(ArrayList<Bitmap> originals){
        ArrayList<Bitmap> results = new ArrayList<Bitmap>();
        ArrayList<Mat> originalMats = new ArrayList<Mat>();
        ArrayList<Mat> resultMats = new ArrayList<Mat>();

        int numOfImages = originals.size();

        long originalMatAddrs[] = new long[numOfImages];
        long resultMatAddrs[] = new long[numOfImages];

        for( int i =0; i < numOfImages; i++) {
            Bitmap bmp = originals.get(i);
            Mat originalMat = new Mat(bmp.getHeight(), bmp.getWidth(), CvType.CV_8UC4);
            Utils.bitmapToMat(bmp, originalMat);
            originalMats.add(originalMat);
            originalMatAddrs[i] = originalMat.getNativeObjAddr();

            Mat resultMat = new Mat(bmp.getHeight(), bmp.getWidth(), CvType.CV_8UC4);
            resultMats.add(resultMat);
            resultMatAddrs[i] = resultMat.getNativeObjAddr();
        }

        //getFeatrueExtractedImages(originalMatAddrs, resultMatAddrs, numOfImages);
        getMatchedFeatureImages(originalMatAddrs, resultMatAddrs, numOfImages);

        for( int i =0 ; i < numOfImages; i++){
            Mat resultMat = resultMats.get(i);
            Bitmap bmp2 = Bitmap.createBitmap(resultMat.cols(), resultMat.rows(), Bitmap.Config.ARGB_8888);
            Utils.matToBitmap(resultMat, bmp2);
            results.add(bmp2);
        }
        return results;
    }

    public ArrayList<Bitmap> stabilizedImages(ArrayList<Bitmap> originals){
        ArrayList<Bitmap> results = new ArrayList<Bitmap>();
        ArrayList<Mat> originalMats = new ArrayList<Mat>();
        ArrayList<Mat> resultMats = new ArrayList<Mat>();

        int numOfImages = originals.size();

        long originalMatAddrs[] = new long[numOfImages];
        long resultMatAddrs[] = new long[numOfImages];

        for( int i =0; i < numOfImages; i++) {
            Bitmap bmp = originals.get(i);
            Mat originalMat = new Mat(bmp.getHeight(), bmp.getWidth(), CvType.CV_8UC4);
            Utils.bitmapToMat(bmp, originalMat);
            originalMats.add(originalMat);
            originalMatAddrs[i] = originalMat.getNativeObjAddr();

            Mat resultMat = new Mat(bmp.getHeight(), bmp.getWidth(), CvType.CV_8UC4);
            resultMats.add(resultMat);
            resultMatAddrs[i] = resultMat.getNativeObjAddr();
        }

        getStabilizedImages(originalMatAddrs, resultMatAddrs, numOfImages);

        for( int i =0 ; i < numOfImages; i++){
            Mat resultMat = resultMats.get(i);
            Bitmap bmp2 = Bitmap.createBitmap(resultMat.cols(), resultMat.rows(), Bitmap.Config.ARGB_8888);
            Utils.matToBitmap(resultMat, bmp2);
            results.add(bmp2);
        }
        return results;
    }
}
