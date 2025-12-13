#include <iostream>
#include <vector>
#include <cmath>
#include <chrono>
#include <fstream>
#include <cstring>

using namespace std;
using namespace chrono;

// Image structure
struct Image {
    int width;
    int height;
    vector<unsigned char> r;
    vector<unsigned char> g;
    vector<unsigned char> b;
    vector<unsigned char> gray;
    
    Image(int w, int h) : width(w), height(h) {
        int size = w * h;
        r.resize(size);
        g.resize(size);
        b.resize(size);
        gray.resize(size);
    }
};

// Function 1: Generate synthetic image data
void generateImageData(Image& img) {
    int size = img.width * img.height;
    for (int i = 0; i < size; i++) {
        img.r[i] = (i * 123) % 256;
        img.g[i] = (i * 456) % 256;
        img.b[i] = (i * 789) % 256;
    }
}

// Function 2: Convert RGB to Grayscale (PARALLELIZABLE)
void convertToGrayscale(Image& img) {
    int size = img.width * img.height;
    for (int i = 0; i < size; i++) {
        img.gray[i] = (unsigned char)(0.299 * img.r[i] + 
                                       0.587 * img.g[i] + 
                                       0.114 * img.b[i]);
    }
}

// Function 3: Calculate average grayscale value (PARALLELIZABLE - Reduction)
double calculateAverageGray(const Image& img) {
    long long sum = 0;
    int size = img.width * img.height;
    for (int i = 0; i < size; i++) {
        sum += img.gray[i];
    }
    return (double)sum / size;
}

// Function 4: Apply brightness adjustment (PARALLELIZABLE)
void adjustBrightness(Image& img, int offset) {
    int size = img.width * img.height;
    for (int i = 0; i < size; i++) {
        int newVal = img.gray[i] + offset;
        if (newVal > 255) newVal = 255;
        if (newVal < 0) newVal = 0;
        img.gray[i] = (unsigned char)newVal;
    }
}

// Function 5: Apply threshold (PARALLELIZABLE)
void applyThreshold(Image& img, unsigned char threshold) {
    int size = img.width * img.height;
    for (int i = 0; i < size; i++) {
        if (img.gray[i] >= threshold) {
            img.gray[i] = 255;
        } else {
            img.gray[i] = 0;
        }
    }
}

// Main function with profiling-friendly structure
int main(int argc, char* argv[]) {
    // Default image size
    int width = 1024;
    int height = 1024;
    
    // Parse command line arguments
    if (argc > 1) {
        width = atoi(argv[1]);
        height = atoi(argv[2]);
    }
    
    cout << "=== Sequential Image Processing Benchmark ===" << endl;
    cout << "Image size: " << width << "x" << height << " pixels" << endl;
    cout << "Total pixels: " << (width * height) << endl << endl;
    
    // Create image
    Image img(width, height);
    
    // Generate synthetic data
    auto start = high_resolution_clock::now();
    generateImageData(img);
    auto end = high_resolution_clock::now();
    cout << "Data generation: " 
         << duration_cast<milliseconds>(end - start).count() << " ms" << endl;
    
    // RGB to Grayscale conversion
    start = high_resolution_clock::now();
    convertToGrayscale(img);
    end = high_resolution_clock::now();
    cout << "Grayscale conversion: " 
         << duration_cast<milliseconds>(end - start).count() << " ms" << endl;
    
    // Calculate average
    start = high_resolution_clock::now();
    double avgGray = calculateAverageGray(img);
    end = high_resolution_clock::now();
    cout << "Average calculation: " 
         << duration_cast<milliseconds>(end - start).count() 
         << " ms (avg = " << avgGray << ")" << endl;
    
    // Brightness adjustment
    start = high_resolution_clock::now();
    adjustBrightness(img, 20);
    end = high_resolution_clock::now();
    cout << "Brightness adjustment: " 
         << duration_cast<milliseconds>(end - start).count() << " ms" << endl;
    
    // Threshold
    start = high_resolution_clock::now();
    applyThreshold(img, 128);
    end = high_resolution_clock::now();
    cout << "Threshold application: " 
         << duration_cast<milliseconds>(end - start).count() << " ms" << endl;
    
    cout << "\n=== Processing Complete ===" << endl;
    
    return 0;
}