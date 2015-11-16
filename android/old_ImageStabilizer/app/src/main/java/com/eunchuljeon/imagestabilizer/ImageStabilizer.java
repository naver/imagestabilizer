package com.eunchuljeon.imagestabilizer;

import android.graphics.Bitmap;
import android.util.Log;
import android.widget.ImageView;

import org.opencv.android.Utils;
import org.opencv.core.Core;
import org.opencv.core.CvType;
import org.opencv.core.KeyPoint;
import org.opencv.core.Mat;
import org.opencv.core.MatOfDMatch;
import org.opencv.core.MatOfKeyPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Scalar;
import org.opencv.core.Size;
import org.opencv.features2d.DescriptorExtractor;
import org.opencv.features2d.DescriptorMatcher;
import org.opencv.features2d.FeatureDetector;
import org.opencv.imgproc.Imgproc;
import org.opencv.video.Video;

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
            }
        }
        return resultMats;
    }

    public ArrayList<Mat> stabilizeWithImageList(ArrayList<Bitmap> originals){
        ArrayList<Bitmap> results = new ArrayList<Bitmap>();
        int numOfImages = originals.size();
        ArrayList<MatOfKeyPoint> keyPointsArr = new ArrayList<MatOfKeyPoint>();
        ArrayList<Mat> descriptorArr = new ArrayList<Mat>();
        ArrayList<Mat> targetImageMats = new ArrayList<>();

        // Extract Features
        for( int i =0; i < numOfImages; i++){
            Bitmap bmp = originals.get(i);
            Mat tmp = new Mat(bmp.getWidth(), bmp.getHeight(), CvType.CV_8UC4);
            Utils.bitmapToMat(bmp, tmp);
            Mat tmp2 = new Mat(bmp.getWidth(), bmp.getHeight(), CvType.CV_8UC4);
            tmp.copyTo(tmp2);
            Imgproc.cvtColor(tmp, tmp, Imgproc.COLOR_BGRA2GRAY);
            targetImageMats.add(tmp2);

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
        System.out.println("Find Inliner matched : " + queryIndexes.size());

        ArrayList< ArrayList<Point> > resultFeature = new ArrayList<>();
        for(int i  = 0; i < numOfImages; i++){
            ArrayList<Point> feature = new ArrayList<>();
            resultFeature.add(feature);
        }

        for( int i = 0; i < queryIndexes.size(); i++){
            ArrayList<Integer> queries = queryIndexes.get(i);
            for(int j =0; j < queries.size(); j++){
                int index = queries.get(j);
                Point point = keyPointsArr.get(j).toArray()[index].pt;
                resultFeature.get(j).add(point);

                if(i ==0 && j ==0){
                    System.out.println("Point : "+point.x+" "+point.y);
                }
            }
        }

        ArrayList<Mat> resultMats = new ArrayList<>();
        resultMats.add(targetImageMats.get(0));

        Mat prevH = new Mat();

        for(int i =1; i < numOfImages; i++){
            MatOfPoint2f mPointSetA = new MatOfPoint2f();
            MatOfPoint2f mPointSetB = new MatOfPoint2f();

            mPointSetA.fromList(resultFeature.get(i - 1));
            mPointSetB.fromList(resultFeature.get(i));

            printMatrix(mPointSetA);

            Mat R = Video.estimateRigidTransform(mPointSetB, mPointSetA, true);

            Mat H = new Mat(3,3, R.type());
            H.put(0,0, R.get(0,0));
            H.put(0,1, R.get(0,1));
            H.put(0,2, R.get(0,2));

            H.put(1,0, R.get(1,0));
            H.put(1,1, R.get(1,1));
            H.put(1,2, R.get(1,2));

            H.put(2,0, 0.0);
            H.put(2,1, 0.0);
            H.put(2,2, 1.0);

            System.out.println("index : " + i);

            printMatrix(H);

            if(i ==1){
                prevH = H;
            }else{
                Core.multiply(prevH, H, prevH);
            }

            int rows = targetImageMats.get(i).rows();
            int cols = targetImageMats.get(i).cols();
            Size size = new Size(rows, cols);

            Mat res = new Mat(rows, cols, CvType.CV_8UC4);
            Mat mask = new Mat(rows, cols, CvType.CV_8UC4);
            mask.setTo(Scalar.all(1));

            Imgproc.warpPerspective(targetImageMats.get(i), res, prevH, size);
            Imgproc.warpPerspective(mask, mask, prevH, size);

            Mat finalRes = new Mat(rows, cols, CvType.CV_8UC4);
            targetImageMats.get(0).copyTo(finalRes);
            res.copyTo(finalRes, mask);
            resultMats.add(finalRes);
        }



//        Video.estimateRigidTransform()

//        for( int i = 0; i < queryIndexes.size(); i++){
//            ArrayList<Integer> queries = queryIndexes.get(i);
//
//            for(int j =0; j < queries.size(); j++){
//                int index = queries.get(j);
//
//                Point point = keyPointsArr.get(j).toArray()[index].pt;
//                Mat tmp = resultMats.get(j);
//                setPixelColor(tmp, (int)point.x, (int)point.y, 5);
//            }
//        }
        return resultMats;
    }

    void printMatrix(Mat mat){
        for( int row = 0; row < mat.rows(); row++){
            for(int col = 0; col < mat.cols(); col++){
                double[] d= mat.get(row, col);
                System.out.print(d[0]+" ");
            }
            System.out.println();
        }
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
