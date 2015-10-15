package com.eunchuljeon.imagestabilizer;

import android.graphics.Bitmap;
import android.widget.ImageView;

import org.opencv.android.Utils;
import org.opencv.core.CvType;
import org.opencv.core.KeyPoint;
import org.opencv.core.Mat;
import org.opencv.core.MatOfDMatch;
import org.opencv.core.MatOfKeyPoint;
import org.opencv.core.Point;
import org.opencv.features2d.DescriptorExtractor;
import org.opencv.features2d.DescriptorMatcher;
import org.opencv.features2d.FeatureDetector;
import org.opencv.imgproc.Imgproc;

import java.util.ArrayList;
import java.util.List;

/**
 * Created by eunchuljeon on 15. 10. 14..
 */
public class ImageStabilizer {

    public float nn_match_ratio = 0.7f;

    public ArrayList<Bitmap> featureExtraction(ArrayList<Bitmap> originals){
        ArrayList<Bitmap> results = new ArrayList<Bitmap>();
        int numOfImages = originals.size();

        for( int i =0; i < numOfImages; i++){
            Bitmap bmp = originals.get(i);
            Mat tmp = new Mat(bmp.getWidth(), bmp.getHeight(), CvType.CV_8UC4);
            Utils.bitmapToMat(bmp, tmp);
            Imgproc.cvtColor(tmp, tmp, Imgproc.COLOR_BGRA2GRAY);

            MatOfKeyPoint keypoints = new MatOfKeyPoint();
            Mat descriptor = new Mat();
            extractFeatureUsingFAST(tmp, keypoints, descriptor);

            KeyPoint[] arrKeyPoints = keypoints.toArray();

            for(int j = 0; j < arrKeyPoints.length; j++){
                setPixelColor(tmp, (int)arrKeyPoints[j].pt.x, (int)arrKeyPoints[j].pt.y,5);
            }

            Bitmap bmp2 = Bitmap.createBitmap(tmp.cols(), tmp.rows(), Bitmap.Config.ARGB_8888);
            Utils.matToBitmap(tmp, bmp2);
            results.add(bmp2);
        }

        return results;
    }

    public ArrayList<Mat> matchedFeatureWithImageList(ArrayList<Bitmap> originals){
        ArrayList<Bitmap> results = new ArrayList<Bitmap>();
        int numOfImages = originals.size();
        ArrayList<MatOfKeyPoint> keyPointsArr = new ArrayList<MatOfKeyPoint>();
        ArrayList<Mat> descriptorArr = new ArrayList<Mat>();
        ArrayList<Mat> resultMats = new ArrayList<>();

        // Extract Features
        for( int i =0; i < numOfImages; i++){
            Bitmap bmp = originals.get(i);
            Mat tmp = new Mat(bmp.getWidth(), bmp.getHeight(), CvType.CV_8UC4);
            Utils.bitmapToMat(bmp, tmp);
            Imgproc.cvtColor(tmp, tmp, Imgproc.COLOR_BGRA2GRAY);
            resultMats.add(tmp);

            MatOfKeyPoint keypoints = new MatOfKeyPoint();
            Mat descriptor = new Mat();
            extractFeatureUsingFAST(tmp, keypoints, descriptor);

            keyPointsArr.add(keypoints);
            descriptorArr.add(descriptor);
        }

        // Match Features
        DescriptorMatcher matcher = DescriptorMatcher.create(DescriptorMatcher.BRUTEFORCE_HAMMING);
        ArrayList<ArrayList<MatOfDMatch>> matchedList = new ArrayList<ArrayList<MatOfDMatch>>();

        for( int i = 1; i < numOfImages; i++){
            ArrayList<MatOfDMatch> matched = new ArrayList<MatOfDMatch>();
            matcher.knnMatch(descriptorArr.get(i-1), descriptorArr.get(i), matched, 2);
            matchedList.add(matched);
        }

        ArrayList< ArrayList<Integer> > queryIndexes = new ArrayList< ArrayList<Integer> >();
        ArrayList< MatOfDMatch > first_nn_matches = matchedList.get(0);

        for( int i =0 ; i < first_nn_matches.size(); i++){
            ArrayList<Integer> queries = new ArrayList<>();
            int queryIdx = first_nn_matches.get(i).toArray()[0].queryIdx;
            int trainIdx = first_nn_matches.get(i).toArray()[0].trainIdx;
            queries.add(queryIdx);
            queries.add(trainIdx);

            if(isInliner(first_nn_matches, queryIdx)){
                boolean inliner = false;

                for(int j = 1; j < matchedList.size(); j++){
                    int nextTrainIdx = matchedList.get(j).get(trainIdx).toArray()[0].trainIdx;

                    if(isInliner(matchedList.get(j), trainIdx)){
                        queries.add(nextTrainIdx);
                        trainIdx = nextTrainIdx;
                        inliner = true;
                    }else{
                        inliner = false;
                        break;
                    }
                }

                if(inliner){
                    queryIndexes.add(queries);
                }
            }
        }

        for( int i = 0; i < queryIndexes.size(); i++){
            ArrayList<Integer> queries = queryIndexes.get(i);

            for(int j =0; j < queries.size(); j++){
                int index = queries.get(j);

                Point point = keyPointsArr.get(j).toArray()[index].pt;
                Mat tmp = resultMats.get(j);
                setPixelColor(tmp, (int)point.x, (int)point.y, 5);

//                Bitmap bmp2 = Bitmap.createBitmap(tmp.cols(), tmp.rows(), Bitmap.Config.ARGB_8888);
//                Utils.matToBitmap(tmp, bmp2);
//                results.add(bmp2);
            }
        }


        return resultMats;
    }

    private void extractFeatureUsingFAST(Mat imageMat, MatOfKeyPoint keypoints, Mat descriptor){
        FeatureDetector fastDetector = FeatureDetector.create(FeatureDetector.FAST);
        fastDetector.detect(imageMat, keypoints);
        DescriptorExtractor descriptorExtractor = DescriptorExtractor.create(DescriptorExtractor.ORB);
        descriptorExtractor.compute(imageMat, keypoints, descriptor);
    }

    private boolean isInliner(ArrayList<MatOfDMatch> nn_matches, int queryIdx){

        float dist1 = nn_matches.get(queryIdx).toArray()[0].distance;
        float dist2 = nn_matches.get(queryIdx).toArray()[1].distance;
        if(dist1 < nn_match_ratio * dist2) {
            return true;
        }else{
            return false;
        }
    }

    private void setPixelColor(Mat mat, int posX, int posY, int size){
        double[] color = {255.0,0.0,0.0,255.0};

        for(int dx = posX-size/2; dx < posX+size/2; dx++){
            for(int dy = posY-size/2; dy < posY+size/2; dy++){
                if( dx >0 && dy > 0 && dx < mat.cols() && dy < mat.rows()){
                    mat.put(dy, dx,color);
                }
            }
        }
    }
}
