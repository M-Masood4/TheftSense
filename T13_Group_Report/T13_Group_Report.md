# Shoplifting Detection System Report

**By:**

- Advait Mathur
- Jack Garrett
- Muhammed Masood
- Sakib Hossain

**Github Repository:** [https://github.com/M-Masood4/TheftSense](https://github.com/M-Masood4/TheftSense)

---

## 1. Introduction

Shoplifting remains a pervasive issue for Irish retailers. A 2024 survey by retail magazine ShelfLife found that every single retailer polled had experienced some form of crime in the past 12 months, with shoplifting cited by 94% of respondents [1]. The Irish Small and Medium Enterprises Association (ISME) estimates that retail crime costs businesses over €1.62 billion annually, a figure consistently referenced in Garda reports and media from 2023–2025 [2][3]. Despite Garda operations like Operation Táirge, which led to over 8,000 arrests in recent years, theft from shops continues to strain limited policing resources.

In response, we developed **TheftSense**, an open-source, privacy-first system that transforms standard CCTV feeds into an intelligent, real-time detection platform. Running edge inference on affordable hardware, it processes 5-second video clips continuously, flags potential shoplifting events (e.g., concealing items, loitering), captures forensic footage, and delivers encrypted uploads to cloud storage with instant notifications. This reduces manual review time and financial losses while prioritizing on-device processing to minimize privacy risks.

### 1.1. Why use Machine Learning for this problem?

Machine Learning (ML) is a branch of artificial intelligence that enables computers to learn patterns from data and make decisions without being explicitly programmed for every possible situation. Instead of following fixed rules, an ML system improves its understanding by analysing examples. In the context of video surveillance, machine learning can be trained to recognize patterns of human behavior – such as normal shopping activity versus suspicious movements associated with shoplifting.

Traditional CCTV systems are passive. They record videos continuously, but they do not understand what they are observing. Human operators must manually monitor screens, which is inefficient, error-prone, and expensive. In busy retail environments, suspicious behavior can easily go unnoticed. Even when motion detection is used, it often triggers false alarms because it cannot distinguish between harmless activity and genuine theft. As a result, conventional camera systems provide evidence after an incident occurs rather than preventing it in real time.

To understand how this works, it is helpful to imagine how humans learn. A child learns to recognize suspicious behaviour not because someone programs exact rules to their mind, but because they observe situations repeatedly and notice patterns. Machine learning works in a similar way. A large collection of labelled examples – in this case, video clips showing normal shopping behavior and shoplifting incidents – is provided to the system. Each clip is tagged with the correct outcome. During training, the model processes these examples and gradually adjusts internal mathematical parameters so that its predictions become more accurate over time.

From a technical perspective, a machine does not "see" like a human. It converts each video frame into numerical values representing colour & intensity. These numbers are processed by layers of mathematical operations that detect patterns such as shapes, motion and changes across time. Early layers may recognize edges or outlines, while deeper layers learn more abstract patterns such as body posture or movement sequences. When multiple frames are analysed together, the system can identify behavioural trends rather than just static images.

A typical machine learning pipeline includes several stages:

1. **Data Collection and Preparation:** Gathering and organizing labelled examples.
2. **Model Training:** Allowing the system to learn patterns from the data.
3. **Validation and Testing:** Measuring how accurately the system performs on unseen examples.
4. **Deployment:** Running the trained model in a real-world environment.

### 1.2. Literature Review

In recent years, researchers have explored using Machine Learning and computer vision to automatically identify suspicious or shoplifting behavior from surveillance videos. Deep Learning techniques aim to address these limitations by teaching computers to see and interpret videos similarly to humans, but at scale and in real time.

This section reviews three relevant research works that focus on detecting shoplifting and suspicious behaviour using deep learning techniques. Each study approaches the problem slightly differently – some focus on early suspicious behaviour, others on real-time detection, and others on temporal modelling of human motion. Understanding these approaches helps position our own work within the broader research landscape.

#### Detection of Pre-Shoplifting Suspicious Behaviour Using Deep Learning [9]

**Authors:** Sujan Shrestha, Yoji Taniguchi, Tetsuo Tanaka

One study by Shreshta, Taniguchi, and Tanaka focuses on pre-shoplifting suspicious behaviours – i.e., actions that may lead up to a theft event. They created a specialized dataset by selecting and segmenting relevant clips from larger crime surveillance collections. Their approach uses deep neural networks that combine spatial and temporal patterns from video data to recognize suspicious movements before an actual theft occurs. This early detection focus distinguishes their work from systems that simply flag theft after it happens.

**Dataset:**

The authors curated a subset of videos from the publicly available UCF Crime Dataset. From this larger surveillance dataset, they extracted video clips representing:

- Normal shopping behaviour
- Suspicious behaviour prior to theft
- Actual shopping incidents

By isolating "pre-crime" segments, they created a dataset tailored to early detection rather than post-event classification.

![Table 1: Dataset Classes](images/table1_dataset_images.png)

**Model Architecture:**

This paper follows a 2D CNN + RNN hybrid architecture. Video clips are decomposed into frames, resized and passed through a MobileNetV2 backbone pretrained on ImageNet for spatial feature extraction. Per-frame feature vectors are sequentially fed into a Bidirectional long short-term memory (BiLSTM) to model temporal dependencies across the clip. The BiLSTM output is flattened and passed through fully connected layers for multi-class classification (Normal, Suspicious, Shoplifting) using softmax. Training uses transfer learning, dropout for regularization, and standard cross-entropy loss. Evaluation relies on accuracy, precision, recall, F-1-score and ROC-AUC.

![Fig 2: Model Diagram](/TheftSense/T13_Group_Report/images/fig2_model_diagram.png)

**Results:**

![Fig 2: Model Diagram](/TheftSense/T13_Group_Report/images/image24.png)

The results highlight several important observations.

First, the model performs strongly in detecting suspicious behaviour, achieving a precision of 0.89 and an F1-score of 0.81, suggesting that the system is relatively effective at identifying behavioural patterns that may precede a shoplifting event.

Second, the model demonstrates a high recall of 0.93 for normal behaviour, indicating that most normal shopping activities are correctly identified as non-suspicious.

However, the model struggles significantly in detecting actual shoplifting events, with a recall of only 0.18, and an F1-score of 0.29. This indicates that many true shoplifting incidents are missed by the model.

Despite this limitation, the authors argue that the primary contribution of the work lies in early detection of suspicious intent rather than final crime classification. By identifying suspicious behaviour early, security personnel may intervene before theft occurs.

**Limitations:**

Although the approach introduces an important concept of early behaviour detection, several limitations remain.

First, the low recall for shoplifting events (0.18) suggests that the model struggles to reliably detect the actual theft action. This may be due to limited examples of shoplifting events in the dataset or the subtle nature of the behaviour.

Second, the dataset is derived from a subset of the UCF Crime dataset, which may not fully represent real-world retail environments. Factors such as camera placement, lighting conditions, crowd density, and occlusion may affect performance in practical deployments.

Third, the model appears to rely primarily on behavioural cues extracted from short clips, which may not fully capture longer-term temporal patterns of human activity.

#### Smart Surveillance: Real-Time Shoplifting Detection Using Deep Learning and YOLOv8 [8]

**Authors:** Vijaya J, Ashutosh Singh, Vaibhav Suntwal, Hatem Al-Dois, Saeed Hamood Alsamhi

This paper emphasizes real-time detection of shoplifting using modern object detection models, particularly Ultralytics' YOLOv8. The focus of this study is on building a system that can operate in live surveillance environments, where speed and computational efficiency are critical.

The paper shows the effectiveness of modern deep learning models in real-time detection. In this approach, the object detection models such as YOLOv8 are used to locate people, objects and actions in video frames. These detections are then used to classify behaviours as either normal or suspicious quickly enough for live monitoring. This work highlights how integrating fast detection models with video analysis can enable scalable and live surveillance systems.

**Dataset:**

The paper utilizes the DCSASS dataset from Kaggle, which consists of videos categorized into 13 different classes. Although the final dataset comprises of 90 normal activity videos and 92 shoplifting instances.

**Model:**

The paper describes training an EfficientNetV2B0 model for the prediction of normal behaviour and shoplifting behavior. YOLOv8 was utilized for object detection, and ByteTracker was used for multi-object tracking.

![efficientNetV2B0 model](/TheftSense/T13_Group_Report/images/image20.png)

**Results:**

![Performance Metrics Of EfficientNetV2B0 Model](/TheftSense/T13_Group_Report/images/performance_efficient.png)

The results indicate that the proposed system achieves high classification performance for both normal and shoplifting activities. In particular, the shoplifting class achieves a precision and recall of 0.94, demonstrating strong capability in correctly identifying theft-related behaviour.

The overall performance metrics, with an F1-score and accuracy of approximately 0.93, suggest that the model provides reliable classification across the dataset.

**Limitations:**

Although the model demonstrates strong performance in distinguishing between normal customer activity and shoplifting behaviour, which is essential for practical surveillance applications, it is important to note that the reported results were obtained under controlled experimental conditions. In real-world retail environments, additional challenges may arise, including:

- Occlusions caused by crowding environments
- Variations in camera angles
- Differences in lighting conditions
- Diverse customer behaviours

These factors may affect the generalization performance of the model when deployed in real-world surveillance systems.

#### Suspicious Behaviour Detection with Temporal Feature Extraction and Time-Series Classification for Shoplifting Crime Prevention [10]

**Authors:** Amril Nazir, Rohan Mitra, Hana Sulieman, Firuz Kamalov

This paper introduces a method that shifts the way video is interpreted. Instead of analysing raw pixels directly, it first tracks individuals through time using object detection and tracking (YOLOv5 with Deep SORT). These tracked movement patterns become a temporal feature sequence – essentially a list of how a person moves over time – which is then classified as suspicious or normal. Treating sequence data this way allows for more efficient and fast comprehension of movement behaviours compared to heavy pixel-based learning. The authors achieved high accuracy and faster inference compared to traditional 3D CNN approaches, demonstrating that temporal patterns are extremely powerful for detecting suspicious behaviour.

**Dataset:**

The authors use the UCF Crime Dataset, specifically focusing on shoplifting-related clips.

After preprocessing and filtering, the dataset contained:

- 267 normal videos
- 50 abnormal (shoplifting) videos
- Expanded into 544 processed clips for training and testing

This dataset closely resembles real surveillance conditions.

**Model:**

Bounding box coordinates of people are extracted from each time frame using YOLOv5 with Deep Sort Tracking, converting video to a tabular time-series format representing object motion. These temporal features are then classified using time-series deep learning models (e.g. InceptionTime, XceptionTime, XCM, MiniRocket).

![Fig 3: Proposed Model Pipeline](/TheftSense/T13_Group_Report/images/fig3_proposed_pipeline.png)

**Results:**

The proposed system achieved:

- F1-score of approximately 92%
- Approximately 8.45x faster inference compared to RFTM (Robust Temporal Feature Magnitude method)

These results indicate that structured temporal feature modelling can outperform heavy 3D CNN-based systems.

**Limitations:**

- Performance depends heavily on accurate tracking; occlusion or crowded scenes may degrade results.
- Stationary suspicious behaviour (minimal movement) may be harder to detect using purely motion-based features.

---

## 2. Architecture Design

Our tech stack comprises of client-side frameworks such as Flutter, server-side technologies such as Amazon Web Services (AWS) and Google Firebase, hardware components such as a Raspberry Pi5 and an Alienware computer with a GPU for training the Machine Learning Model, and other development tools including Git version control.

### 2.1 Raspberry Pi 5

We used the Raspberry Pi 5 (8GB RAM variant with 32GB microSD storage) as the central edge computing platform for TheftSense. This choice was driven by its excellent balance of affordability (typically €75–€110 in Ireland), extremely low power consumption (around 4–5W idle, peaking at ~10–12W during inference), and sufficient compute capability for our real-time shoplifting detection pipeline. The quad-core ARM Cortex-A76 CPU at 2.4 GHz, combined with 8GB LPDDR4X RAM, handles optimized lightweight models (YOLOv8) at acceptable frame rates for processing 5-second video clips on-device. This enables privacy-preserving inference, detecting behaviors like item concealment or loitering locally. The annotated videos are encrypted and uploaded back to S3 in a marked bucket, aligning with GDPR considerations for retail environments in Ireland.

The Pi 5 also benefits from a mature, well-documented ecosystem (libcamera for seamless CSI camera control, extensive Python/Bash tooling, and strong community support), which significantly accelerated development and debugging. Its compact size, silent operation, and simple power requirements make it ideal for unobtrusive, always-on deployment in small-to-medium shops, where long-term reliability and minimal running costs are essential.

#### 2.1.1 Headless Setup via Tailscale

Secure, reliable remote access to the Raspberry Pi 5 was essential for our headless development workflow, given the lack of local peripherals (e.g., no HDMI monitor) and the need to work across multiple networks during the project. We chose Tailscale, an open-source, user-space WireGuard VPN, for its simplicity, zero-configuration setup, and end-to-end encryption, which provided a fixed virtual IP for the Pi regardless of the underlying network. This allowed seamless SSH and RDP sessions from home, university, or mobile locations, without exposing ports publicly or dealing with dynamic IPs and NAT traversal manually. Tailscale's design (using DERP relays for connectivity when direct peer-to-peer fails) aligned well with our privacy-focused architecture, ensuring all traffic remained encrypted and minimizing attack surfaces in a potential retail deployment.

The setup began after the initial headless bootstrapping of the Pi. With Raspberry Pi OS flashed onto the microSD card (using a friend's USB adapter, as no direct reader was available at home), we pre-enabled SSH and Wi-Fi via Raspberry Pi Imager. Once powered on and connected to home Wi-Fi, we SSH'd in (`ssh masood@mas.local`) and installed Tailscale with a single command:

```bash
curl -fsSL https://tailscale.com/install.sh | sh
```

Authentication followed with `tailscale up`, linking the device to our tailnet (owned by M-Masood4@github, display name Masood). This assigned a persistent Tailscale IP (100.69.56.10), visible in the admin console (login.tailscale.com/admin). We then installed xrdp (`sudo apt install xrdp`) to enable full graphical remote desktop access, useful for previewing camera feeds or debugging GUI tools like `rpicam-hello`.

Accessing the Pi across networks presented varied challenges, which we resolved iteratively. On home Wi-Fi, connectivity was straightforward — Tailscale handled NAT punching automatically for direct SSH/RDP. At university eduroam, proxy restrictions and firewall rules occasionally caused initial connection delays; Tailscale's DERP relays (fallback servers) mitigated this by routing traffic indirectly, though we sometimes verified the Pi's status via `tailscale status` to confirm it was online (green indicator in the console). The mobile hotspot was trickier: without automatic discovery, we manually identified the Pi's local IP by accessing the hotspot's admin interface (e.g., 192.168.1.1) to list connected devices, cross-checking with the laptop's connected devices list, and running `ipconfig` (on Windows) or `ip addr` (on Linux) to confirm the subnet. Once located, SSH over the local IP bootstrapped Tailscale if needed, ensuring the virtual IP took over for stable access. Intermittent issues like brief disconnections (e.g., due to eduroam session timeouts) were addressed by restarting the Tailscale service (`sudo tailscale down && sudo tailscale up`) or checking logs (`tailscale debug prefs`).

Broader tailnet management revealed additional hurdles, particularly when sharing access with team members. The tailnet supported only two users initially (owner and one admin invitee), and ACL policies defaulted to broad allows (`autogroup:member → *:*`). However, inviting partners (e.g., via Gmail) sometimes led to offline/gray status in the console, requiring auth key generation (`tskey-...`) for re-joining. We avoided common pitfalls like switching tailnets without logout, ensuring users selected the correct one ("m-masood4") during login. For Windows-based team devices, flashes of the `tailscale.exe` window or "NoState" errors (indicating daemon IPC failures) were not encountered on the Pi but informed our troubleshooting mindset — emphasizing admin runs, unattended mode (`tailscale up --unattended`), and clean reinstalls if needed.

This Tailscale integration not only resolved our multi-network mobility needs but also served as a model for production: in a shop, the Pi could be remotely monitored/updated securely, with push notifications for status changes. The process highlighted key lessons in open-source networking, prioritizing simplicity and diagnostics (e.g., `tailscale ping --verbose`, `tailscale netcheck`) to overcome real-world variability in connectivity.

#### 2.1.2 Camera Compatibility + Trade-offs

The choice of camera module was a critical architectural decision, balancing performance requirements for real-time shoplifting detection (object detection, action classification via models like YOLOv8 combined with temporal analysis), hardware compatibility across platforms, setup complexity, cost, and project timelines. We evaluated several options available through Farnell.ie (preferred for UCC purchasing and quick delivery), leveraging the borrowed Raspberry Pi High Quality (HQ) Camera (Sony IMX477 sensor, CS-mount, lens-less) as the starting point.

**Key options considered:**

- **15-pin to 22-pin CSI Adapter Cable:** Essential for connecting any standard 15-pin CSI camera (including the HQ/IMX477) to the Pi 5's smaller 22-pin ports. These shielded FPC cables ensure reliable signal integrity and are widely used for Pi 5 upgrades. Without one, the Pi 5 cannot interface with legacy 15-pin modules.
- **Raspberry Pi Camera Module 3:** A compact, cost-effective autofocus module with a 12MP sensor, ~66° horizontal FOV, HDR, and phase-detection autofocus. It offers plug-and-play ease on Pi 5 (with adapter cable) and sharp video suitable for retail scenes. However, its fixed lens and smaller sensor limit low-light performance and customization compared to the HQ.
- **6mm CS-Mount Lens for HQ Camera:** Adds wide-angle coverage (~63–65° FOV) to the borrowed HQ Camera, enabling manual focus for precise retail aisle tuning. This revives the lens-less module but requires manual adjustment and the adapter cable for Pi 5.
- **Raspberry Pi AI Camera (SC1174):** Features the Sony IMX500 Intelligent Vision Sensor (12MP) with onboard AI acceleration, enabling low-latency inference (e.g., running quantized models directly on the sensor). This offloads CPU/GPU workload on the Pi 5, ideal for edge AI tasks like our shoplifting detection pipeline. It integrates seamlessly with Pi 5 (often with included or standard cabling) and supports frameworks like rpicam-apps with AI overlays.

**Trade-offs and Final Decision**

The primary dilemma centered on cross-platform compatibility versus Pi 5-specific optimization. The AI Camera excels for Raspberry Pi 5 deployments, offering reduced latency and power efficiency for inference, but lacks driver support for the NVIDIA Jetson Nano (which natively supports IMX219 and IMX477 sensors via nvargus/GStreamer pipelines). The Jetson Nano's CUDA/TensorRT acceleration makes it attractive for heavier models or faster batch processing during development.

To enable direct performance comparison between the Pi 5 (energy-efficient, mature libcamera ecosystem) and Jetson Nano (GPU-accelerated inference), we prioritized universality. The IMX477-based HQ Camera supports both platforms: direct 15-pin connection on Jetson Nano (with community-confirmed drivers, sometimes requiring minor modifications like resistor removal for power stability on certain carriers) and Pi 5 via the adapter cable. This avoided vendor lock-in and allowed testing the same sensor/input pipeline on both, crucial for benchmarking inference latency, power draw, and accuracy in our use case.

Alternatives like the Camera Module 3 were appealing for simplicity and autofocus but offered less flexibility (smaller sensor, fixed lens) and no inherent cross-platform advantage over the HQ setup.

Ultimately, we selected the **6mm CS-mount lens plus the 15-to-22 pin adapter cable** for the existing borrowed HQ Camera. This path was cost-effective, maximized hardware reuse, and preserved experimentation across both platforms.

In practice, the Jetson Nano option, generously offered by Prof. Zahran, arrived later in the project timeline. By the time the Pi 5 was fully set up headlessly (with Tailscale, xrdp, and camera operational), time constraints for integration, data labeling (~600 clips), model training, and Flutter app development made comprehensive Jetson testing unfeasible. The project thus focused on the Raspberry Pi 5 as the primary edge device, with the HQ Camera + lens + adapter delivering reliable 1280x720 video capture for on-device inference and 5-second forensic clips.

This decision reflects common open-source hardware trade-offs (as seen in embedded vision projects): prioritizing interoperability and rapid iteration over specialized acceleration when timelines are tight. Future extensions could revisit the AI Camera for Pi-only optimizations or pursue Jetson integration with dedicated drivers if performance gaps warrant it.

> _Fig 1. The Raspberry Pi connected to the HQ Camera via a 500mm CSI cable, with a 6mm lens attached._
![Fig 1: Raspberry Pi](/TheftSense/T13_Group_Report/images/pi5.jpg)

### 2.2 Amazon Web Services

Early on, we knew that data friction issues would end up being a bottleneck. To address this, we chose to use Amazon Web Services on the back-end to avoid forcing users to store terabytes of videos locally. S3 allows you to store data in 'buckets' without the need to define datatypes beforehand, unlike Java where you need to declare what datatype a list must contain.

> _Fig 2. An S3 bucket containing training videos for the model_
![Fig 2: S3 bucket](/TheftSense/T13_Group_Report/images/s3_bucket.png)

Using the AWS Software Development Kit (SDK) for python we were able to make a program that would take an input folder of videos and split them into training, testing, and validation sets, and then upload them to an S3 bucket. The benefit of this was that we could later access videos in the bucket on-demand when training the model and when accessing videos through the app. Here is an example of a python function to upload objects to the bucket from the AWS documentation:

```python
def put_object(s3_client, bucket_name, key_name, object_bytes):
    """
    Upload data to a directory bucket.

    :param s3_client: The boto3 S3 client
    :param bucket_name: The bucket that will contain the object
    :param key_name: The key of the object to be uploaded
    :param object_bytes: The data to upload
    """
    try:
        response = s3_client.put_object(
            Bucket=bucket_name, Key=key_name, Body=object_bytes
        )
        print(f"Uploaded object '{key_name}' to bucket '{bucket_name}'.")
        return response
    except ClientError:
        print(f"Couldn't upload object '{key_name}' to bucket '{bucket_name}'.")
        raise
```

However, buckets aren't just plug-and-play. Throughout production every member of the team needed to be able to manage the buckets which is where **AWS Identity & Access Management (IAM)** comes in. IAM manages authentication and authorization, that is, for each member of the group that isn't the bucket owner, an IAM user with access keys must be created and granted permissions using IAM policies. Then, a user can configure their local environment using `aws configure` and the credentials that they were provided with to manage the buckets from their local machine. An example of an IAM policy that allows a user to put objects, get objects, and delete objects from a bucket is displayed below (written in JavaScript Object Notation (JSON)):

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ListBucket",
      "Effect": "Allow",
      "Action": "s3:ListBucket",
      "Resource": "arn:aws:s3:::t13-marked-videos"
    },
    {
      "Sid": "ObjectAccess",
      "Effect": "Allow",
      "Action": ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"],
      "Resource": "arn:aws:s3:::t13-marked-videos/*"
    }
  ]
}
```

### 2.3. The Model

#### 2.3.1. Methodology

This section describes the methodology used to develop the proposed shoplifting detection system. The objective of the system is to automatically analyze surveillance video footage and determine whether shoplifting activity is occurring.

The proposed approach combines person-focused object detection, spatial feature extraction and temporal sequence modelling to capture both visual and behavioural patterns in surveillance videos. The system processes video data through multiple stages, including preprocessing, feature extraction, temporal modelling, and classification.

The overall pipeline consists of the following stages:

1. Dataset collection and preparation
2. Video preprocessing and frame sampling
3. Data augmentation
4. Person detection and region cropping
5. Spatial feature extraction
6. Temporal sequence modelling
7. Attention-based temporal pooling
8. Binary classification
9. Model training and optimization
10. Performance evaluation

#### Dataset Collection and Preparation

The dataset used in this project consists of over 950 video samples collected from multiple sources. The primary source of real surveillance footage was the UCF Crime Dataset, which contains recordings of various anomalous activities captured in real-world environments such as retail stores, public spaces, and streets. Videos belonging to the shoplifting category were extracted from this dataset.

Since real-world shoplifting footage is limited, additional curated datasets created by previous research studies were also incorporated. These datasets contain staged scenarios designed to simulate suspicious retail behaviours. Combining real and simulated examples increases the diversity of behavioural patterns available for training.

Each video in the dataset is labelled as one of two classes:

1. **Normal (0)** – No suspicious behaviour present
2. **Shoplifting (1)** – Behaviour associated with shoplifting activity

The dataset is divided into three subsets:

1. **Training Set** – Used for learning model parameters
2. **Validation Set** – Used for hyperparameter tuning and performance monitoring
3. **Test Set** – Used for final evaluation of model performance

To simplify data management and enable scalable training, all videos are stored in Amazon S3 cloud storage. Instead of storing raw file paths, the dataset loader uses manifest files, where each line specifies the video location and label.

#### Video Preprocessing and Frame Sampling

Surveillance videos typically contain hundreds or thousands of frames, many of which may not contain meaningful information for behavioural analysis. To standardize the input for the neural network, each video is converted into a fixed-length sequence of **50 frames**.

Frames are sampled uniformly across the duration of the video. This ensures that the selected frames represent the entire activity rather than focusing only on a specific portion of the clip.

Each frame is later resized to a spatial resolution of **224 × 224 pixels**, which is compatible with the convolutional neural network used for spatial feature extraction.

Pixel values are also normalized to the range [0,1], enabling consistent numerical representation for neural network training.

#### Data Augmentation

To improve the model's ability to generalize to different surveillance environments, data augmentation techniques are applied during training. Data augmentation artificially increases the diversity of the dataset by applying random transformations to input images while preserving their semantic meaning.

Surveillance footage often varies in lighting conditions, camera positions, and environmental settings. Augmentation helps the model become robust to such variations.

The augmentation pipeline is implemented using PyTorch's torchvision transformation framework and includes the following transformations:

1. **Random Horizontal Flip (p = 0.5)**
   Frames are randomly flipped horizontally with a probability of 50%. This enables the model to learn behaviour patterns that may occur in either direction within a scene.

2. **Colour Jitter**
   Random variations are applied to brightness, contrast, saturation, and hue to simulate different lighting conditions.
   - Brightness: ±20%
   - Contrast: ±20%
   - Saturation: ±20%
   - Hue: ±10%

3. **Image Resizing**
   All frames are resized to 224 × 224 pixels to match the input size required by the EfficientNetV2 architecture.

4. **Tensor Conversion**
   Frames are converted into PyTorch tensors to allow efficient GPU-based computation.

![Tensor Conversion](/TheftSense/T13_Group_Report/images/tensor.png)

These transformations are applied only to the training data, while validation and test datasets remain unchanged to ensure unbiased evaluation.

#### Person Detection and Region Cropping

Surveillance frames often contain significant background information that is unrelated to human activity. Elements such as store shelves, walls, or other customers may introduce noise that can interfere with the learning process.

To address this issue, the system incorporates a person detection stage using **YOLOv8n**. YOLO (You Only Look Once) is a real-time object detection algorithm capable of detecting multiple object classes within an image. In this project, YOLOv8n is used specifically to detect persons (class label 0) within each frame.

For every sampled frame:

1. YOLOv8n detects objects within the image
2. The first detected person bounding box is selected
3. The region inside the bounding box is cropped
4. The cropped region is resized to 224 × 224 pixels

If no person is detected in a frame, the entire frame is used instead.

This preprocessing step ensures that the model focuses primarily on human posture and motion, which are important cues for identifying shoplifting behaviour.

![crop_person](/TheftSense/T13_Group_Report/images/crop_person.png)

#### Spatial Feature Extraction

Once frames are cropped and resized, spatial visual features are extracted using a deep convolutional neural network.

The system uses **EfficientNetV2-S** as the feature extractor. EfficientNetV2 is a modern CNN architecture designed to achieve high accuracy while maintaining computational efficiency. In this implementation:

- The model is initialized with ImageNet pretrained weights.
- The final classification layer is removed.
- The network outputs a **1280-dimensional feature vector** for each frame.

Each frame is processed independently by the spatial encoder, converting raw pixel data into a compact numerical representation describing important visual characteristics such as shapes, textures and object configurations.

For a video clip containing 50 frames, the spatial encoder produces 50 feature vectors, one for each frame.

![Spatial Encoder](/TheftSense/T13_Group_Report/images/spatial_encoder.png)

#### Temporal Sequence Modelling

While spatial features describe individual frames, shoplifting behaviour is defined by actions that occur across time. Activities such as concealing items, placing objects into bags, or repeatedly looking around unfold across multiple frames.

To capture these temporal dependencies, the system uses a **Transformer-based temporal encoder**.

The temporal module performs the following operations:

1. Frame-level features are projected into a **768-dimensional embedding space**.
2. A learnable positional encoding is added to preserve the order of frames.
3. The sequence is processed through **three Transformer encoder layers** with **eight attention heads**.

The self-attention mechanism allows the model to identify which frames contribute most strongly to the detection of suspicious behaviour.

![forward](/TheftSense/T13_Group_Report/images/forward.png)

#### Attention-Based Temporal Pooling

After temporal processing, the sequence of frame representations must be converted into a single vector representing the entire clip.

Instead of using simple averaging, the model applies **attention-based temporal pooling**. This mechanism assigns learnable weights to each frame, allowing the model to emphasize frames that contain important behavioural cues.

The weighted representations are combined into a single vector that summarizes the overall activity in the video.

![Forward](/TheftSense/T13_Group_Report/images/forward2.png)

#### Classification Layer

The final component of the system is a fully connected classification network that predicts whether shoplifting behaviour is present.

The classifier includes several dense layers with:

- ReLU activation functions
- Batch Normalization
- Dropout regularization

The final output layer produces a single logit value, which is converted into a probability using the **sigmoid activation function**.

This probability represents the likelihood that the input video contains shoplifting activity.

![Classification](/TheftSense/T13_Group_Report/images/classifier.png)

#### Training Strategy

A two-stage training strategy is used to improve training stability and performance.

**Phase 1: Frozen Backbone Training**

Initially, the spatial feature extractor (EfficientNetV2) is frozen, meaning its parameters are not updated during training. Only the temporal encoder and classification layers are trained. This allows the model to learn temporal relationships without disrupting the pretrained visual representations.

**Phase 2: Fine-Tuning**

After several epochs, selected layers of the spatial encoder are unfrozen and fine-tuned using a smaller learning rate. This allows the feature extractor to adapt to surveillance imagery while preserving previously learned features.

![Training Strategy](/TheftSense/T13_Group_Report/images/epoch.png)

#### Loss Function and Optimization

The model uses **Focal Loss** as the training objective. This loss function is designed to address class imbalance by giving greater importance to difficult training examples.

In shoplifting detection datasets, normal behaviour typically appears more frequently than suspicious activity. Focal loss helps the model focus on correctly identifying the relatively rare shoplifting events.

Training is performed using the **AdamW optimizer**, which combines adaptive learning rates with weight decay regularization to improve generalization.

Additionally, **mixed precision training** using PyTorch Automatic Mixed Precision (AMP) is used to reduce memory consumption and accelerate training on GPU hardware.

![Focal Loss](/TheftSense/T13_Group_Report/images/focalloss_1.png)
![Focal Loss](/TheftSense/T13_Group_Report/images/focalloss_2.png)

#### Evaluation Metrics

Model performance is evaluated using several standard classification metrics. These metrics are derived from the confusion matrix, which summarizes the outcomes of model predictions.

**Confusion Matrix**

A confusion matrix is a table used to describe the performance of a classification model by comparing predicted labels with actual ground truth labels.

For binary classification, the confusion matrix consists of four components:

|                        | Predicted Shoplifting | Predicted Normal    |
| ---------------------- | --------------------- | ------------------- |
| **Actual Shoplifting** | True Positive (TP)    | False Negative (FN) |
| **Actual Normal**      | False Positive (FP)   | True Negative (TN)  |

Where:

- **True Positive (TP):** Shoplifting correctly detected by the model
- **True Negative (TN):** Normal activity correctly classified as normal
- **False Positive (FP):** Normal activity incorrectly classified as shoplifting
- **False Negative (FN):** Shoplifting activity incorrectly classified as normal

The confusion matrix provides the foundation for computing the evaluation metrics described below.

**Accuracy**

Accuracy measures the overall proportion of correctly classified samples among all predictions:

$$\text{Accuracy} = \frac{TP + TN}{TP + TN + FP + FN}$$

Accuracy provides a general overview of how often the model makes correct predictions. However, in anomaly detection, accuracy alone can be misleading. For example, if most videos contain normal behaviour, a model that predicts "normal" for every sample may achieve high accuracy while completely failing to detect shoplifting incidents. Therefore, additional metrics such as precision and recall are necessary.

**Precision**

Precision measures the proportion of predicted shoplifting cases that are correct:

$$\text{Precision} = \frac{TP}{TP + FP}$$

High precision means that when the model raises an alert, it is likely to be correct. Precision is particularly important in surveillance systems because false alarms can cause unnecessary security responses. A model with low precision would frequently misclassify normal behaviour as shoplifting, leading to excessive alerts and reduced trust in the system.

**Recall**

Recall measures the proportion of actual shoplifting incidents that the model successfully detects:

$$\text{Recall} = \frac{TP}{TP + FN}$$

High recall indicates that the model can detect most instances of shoplifting behaviour. Recall is critical in security applications because missing a shoplifting event may result in financial loss for the store. A model with low recall would fail to identify many suspicious events. However, optimizing recall alone can lead to excessive false alarms. Therefore, a balance between recall and precision must be maintained.

**F1 Score**

The F1 Score is the harmonic mean of precision and recall. It provides a single metric that balances both false positives and false negatives:

$$F_1 = 2 \times \frac{\text{Precision} \times \text{Recall}}{\text{Precision} + \text{Recall}}$$

The harmonic mean ensures that both precision and recall must be high for the F1 score to be high. If either precision or recall is low, the F1 score will decrease significantly. The F1 score is particularly useful in imbalanced classification problems, where one class appears more frequently than the other. In the case of shoplifting detection, normal behaviour typically appears far more often than suspicious activity. For this reason, the F1 score is used as the **primary metric for model selection** in this project.

#### Threshold Optimization

The model outputs a probability value between 0 and 1 representing the likelihood that a video contains shoplifting behaviour. To convert this probability into a binary classification decision, a threshold must be selected.

During validation, different probability thresholds were evaluated within the range:

$$0.2 \leq \text{threshold} \leq 0.6$$

For each threshold value, precision, recall and F1 score were calculated. The threshold that produced the most balanced scores (**0.42**) on the validation dataset was selected as the final decision threshold.

Optimizing the threshold in this way ensures that the model achieves the best balance between detecting suspicious behaviour and avoiding excessive false alarms.

![Threshold](/TheftSense/T13_Group_Report/images/threshold.png)

The model produced the following Prediction confidence and Probability Distribution:

![Probability Distribution](/TheftSense/T13_Group_Report/images/prob_dist.png)

The probability distribution shows distinct clustering of normal and shoplifting instances with partial overlap in the 0.35–0.55 confidence range. This overlap corresponds to ambiguous behavioural patterns where subtle motion cues challenge the temporal model.

#### Grad-CAM

Gradient-weighted Class Activation Mapping (Grad-CAM) is a visualization technique used in deep learning to help explain how a neural network makes a decision. In video analytics and computer vision systems, models analyse frames of a video to detect objects, actions, or events. However, these models are often considered "black boxes", meaning it can be difficult to understand why the model produced a particular prediction.

Grad-CAM addresses this issue by highlighting the areas of an image or video frame that the model focused on when making its decision.

Grad-CAM works by using the gradients (signals used during model training) flowing into the final convolutional layer of a neural network. These gradients indicate which features in the image were most influential for predicting a specific class. The method combines this gradient information with the activation maps of the network to produce a heatmap that is overlaid on the original image or frame. Warmer colours (red) represent regions that had a stronger influence on the model's prediction, while cooler colours indicate less influence.

Here the Grad-CAM is applied to a sequence of frames for a clip. It visually highlights the regions of the video frame that contributed most to the detection. This includes a person's hands interacting with an item, movement near a shelf etc. By visualizing this attention, we can verify that the model is focusing on meaningful parts of the scene rather than irrelevant background details.

Another key benefit of Grad-CAM is its usefulness in model debugging and validation. The highlighted regions correspond to the correct objects or actions in the frame; it provides confidence that the model is learning relevant visual features.

Overall, Grad-CAM has been an effective tool for making the proposed model explainable and trustworthy. By visually illustrating how it arrives at its prediction, it bridges the gap between complex algorithms and human understanding, which has been particularly valuable in our system.

![Grad-Cam 1](images/gradcam_YOLO_frame_clip1_0.png) ![Grad-Cam 1](images/gradcam_YOLO_frame_clip1_1.png) ![Grad-Cam 1](images/gradcam_YOLO_frame_clip1_2.png) ![Grad-Cam 1](images/gradcam_YOLO_frame_clip1_3.png) ![Grad-Cam 1](images/gradcam_YOLO_frame_clip1_5.png) ![Grad-Cam 1](images/gradcam_YOLO_frame_clip2_0.png) ![Grad-Cam 1](images/gradcam_YOLO_frame_clip2_1.png) ![Grad-Cam 1](images/gradcam_YOLO_frame_clip2_2.png) ![Grad-Cam 1](images/gradcam_YOLO_frame_clip1_3.png) 
 

 






*Grad Cam Examples*

#### Test Results

The final trained model was evaluated on a test dataset containing **474 video samples**.

The model achieves **74% accuracy** with **73.5% recall** on shoplifting detection, prioritizing theft detection over false alarms. The **F1 score of 0.69** indicates balanced performance given behavioural ambiguity in real-world retail scenarios.

![Test Results](images/results.png) 

*Test Results*


These results demonstrate that combining person detection, spatial feature extraction, and temporal modelling provides an effective framework for automated shoplifting detection in surveillance videos.

### 2.4. Flutter

The app would be designed using **Flutter** — an open source framework for building, testing and deploying multi-platform applications from a single codebase — and would be programmed using **Dart**, an object oriented programming language with a clear and simple syntax similar to Java.

Dart is an approachable and portable language that was developed by Google to help developers such as ourselves develop an application that can be used across multiple platforms. It features null safety and asynchronous programming, the former of which doesn't exist in Python. For example, the following code:

```dart
VideoPlayerController? _controller;
await _controller!.dispose();
```

tells the compiler that the `VideoPlayerController` can be null (using `?`), and that you are required to handle it later on. However, when we get to `_controller!.dispose()`, the exclamation point is an assertion that the controller must not be null. Think of it as an `if` statement, except that it must always be true or else it throws an exception.

Aside from the benefits of our chosen language, let's talk about the front-end and how various components were designed to make the user experience as smooth as possible. Firstly, the app is split into 4 major pages — **Home**, **Cameras**, **History**, and **Settings** — with each 'page' owning a separate Dart file for modularization to simplify complexity and improve maintainability.

The core problem was deciding how the data would flow. A user story goes as follows: _"As a shop owner, I want to connect my camera to this app so that it automatically notifies me when a shoplifting incident occurs."_

![Grad-Cam 1](images/dataflow.png) 

*Level 0: Dataflow Diagram*


When the user first logs into the app, they will be greeted by an empty dashboard, so they should navigate to the 'cameras' page to connect a camera to the app. Once the camera is connected, a process begins in the background where every 5 seconds a video clip is taken and processed (which we will discuss in implementation details), then when the user navigates to the 'history' page, the app will download incidents from the S3 bucket where the processed videos are stored for review.

The user story defined a minimum viable product for the system, but we also planned to include additional quality of life features such as a dashboard summarizing recent incidents, a filter tab in 'history' to group incidents by severity or time of occurrence, and a notification system for which we would need Google Firebase.

### 2.5. Google Firebase

User authentication was done using **Google Firebase** — a cloud platform that provides ready-to-use backend services such as databases, authentication, hosting, and analytics for applications.

Before any authentication actions can occur, the application must establish a connection with the Firebase project, which was done using the configuration credentials generated within the Firebase console.

```dart
static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCxqFt5R-9WFzUw0po_qY1LKtLuweaiqmM',
    appId: '1:825353246981:web:9652ab1ce3bdbf0a353f6c',
    messagingSenderId: '825353246981',
    projectId: 'group-project-666b6',
    authDomain: 'group-project-666b6.firebaseapp.com',
    storageBucket: 'group-project-666b6.firebasestorage.app',
    measurementId: 'G-87SX2PJ2S1',
);
```

_(This information is public and doesn't need to be hidden before pushing)_

Once initialized, the application can access Firebase services including authentication and database functions.

```dart
await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
);
```

The first course of action was to provide a traditional **email and password login** mechanism for users who prefer to create an account directly within the system. Firebase securely stores the hashed credentials and manages authentication tokens for subsequent sessions. Firebase generates a secure session token that the application uses to maintain the user's authenticated state. This method provides a straightforward authentication flow while maintaining strong security practices through Firebase's managed infrastructure.

```dart
final credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
    email: email,
    password: password,
);
```

A useful feature that Firebase offers to ensure users register with a valid email address is the **email verification** feature. After a user successfully creates an account, Firebase automatically sends a verification email containing a confirmation link. Once the user clicks the verification link, Firebase marks the email as verified within the authentication record, and automatically redirects the user to the home page of the application. The code required to do this redirection is as follows:

```dart
await user.reload();
final refreshedUser = FirebaseAuth.instance.currentUser;
if (refreshedUser != null && refreshedUser.emailVerified) {
    if (!mounted) {
        return;
    }
    _pollingTimer?.cancel();
    Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
            builder: (context) => const MyHomePage(title: 'TheftSense'),
        ),
        (route) => false,
    );
}
```

This code fetches the latest user data from the Firebase servers by reloading, does the checks to confirm a user is actually logged in and clicks the verification link in their email and then navigates to the home page, removing every previous route in the process. A polling timer was created to ensure this functionality worked, as it polled Firebase every five seconds until it was stopped. Finally, the actual email verification was done as follows:

```dart
await user.sendEmailVerification();
```

Users who forget their password can initiate a **password reset** through the system as well. The process uses Firebase's password recovery mechanism, which sends a password reset email to the verified email. The reset email contains a secure link allowing the user to set a new password. Firebase manages the entire recovery process, including token validation and expiration. This ensures secure account recovery and password changes without exposing sensitive authentication data within the application.

There were two instances within our application where this mechanism was implemented; the forgot password page and the change password section in the settings page. Both use the implementation as follows:

```dart
await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
```

To simplify the login process and reduce password management overhead, the application supports authentication using **Google Sign-In**. Google Sign-In allows users to authenticate using their existing Google account. The authentication flow involves redirecting the user to Google's identity provider, where they grant permission for the application to access basic profile information. Once authenticated, Firebase securely links the Google account with the Firebase user identity and issues the appropriate authentication token.

```dart
final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
);
```

The final feature implemented using Firebase was **account deletion**. Users are provided with the option to permanently delete their account from the system. When this action is triggered, Firebase removes the user's authentication record from the authentication database. To ensure intentional deletion of the account, the user has to re-authenticate, before being met with a final confirmation message, so that the deletion can by no means be done by accident. This then results in the removal of the Firebase authentication record.

This functionality ensures compliance with privacy best practices and allows users to maintain full control over their personal data.

```dart
await user.delete().timeout(const Duration(seconds: 15));
```

After re-authentication is complete, and the confirm deletion button is pressed, the code above runs, before redirecting the user back to the landing page, with a snack bar saying 'Account deleted'. On the Firebase project site, the user's authentication record has been entirely removed from among the verified users.

For clarity, here is a data flow diagram for user registration and email verification to show how the main process functions:

![Dataflow 2](images/userflow.png) 


---

## 3. Implementation Details

Discussing what tools we would use is one thing. But getting each component to work as a unified system is another. Challenges arise from our earlier choices that we need to acknowledge and work around.

### 3.1. API Calls To AWS

We can't expect the user to manually upload videos, which is why we need Flutter to make requests to AWS to upload/download videos from the relevant buckets. However, we can't just make requests directly to the bucket, that would be bad practice. Instead, we use the `boto3` library included in the AWS SDK (Software Development Kit) for Python to programmatically manage the bucket.

Another problem arises — we are unable to directly call functions in a `.py` file from a `.dart` file. If you have studied web development, you know that we can use a Flask app running alongside Flutter to handle web requests and return responses. Similar to how JavaScript can send requests to a Flask application, enabling interactions between the browser and the server.

```python
import boto3
from flask import Flask
from flask_cors import CORS

s3 = boto3.client("s3", region_name="eu-west-1")
app = Flask(__name__)
CORS(app)

@app.route("/fetch_incidents")
def fetch_incidents():
    ### Insert Code Here
```

With the setup displayed above, Flutter can make an HTTP request to the Flask app and get a response in the form of a JSON body which can be parsed by Dart to extract the relevant information including the URLs of the videos stored in the bucket. You might also notice that we use CORS (Cross-Origin Requests) as we are hosting our application on the browser and we need Flask to accept incoming requests from any source.

### 3.2. The Video Processing System

#### System Implementation & Deployment

After training the shoplifting detection model, the system was deployed as an edge-based video analysis pipeline capable of processing surveillance footage and generating alerts when suspicious behaviour is detected. The deployment architecture integrates Raspberry Pi 5 edge computation, cloud storage using Amazon S3, and automated email notification services.

The deployment system processes surveillance videos uploaded to cloud storage, performs inference on the edge device, and returns annotated results along with alert notifications. This section describes the implementation details of the deployment pipeline.

#### Edge Deployment on Raspberry Pi

The inference system is deployed on a Raspberry Pi 5, which acts as an edge computing device responsible for processing surveillance footage locally. Edge deployment reduces latency and allows the system to operate without relying on continuous high-bandwidth cloud communication.

The Raspberry Pi runs a Python-based inference script (`inference.py`) that performs the following tasks:

1. Retrieves surveillance videos from cloud storage.
2. Processes the video using detection and temporal classification models.
3. Determines whether shoplifting activity is present.
4. Generates an annotated output video.
5. Sends alerts if suspicious activity is detected.

The inference pipeline runs on CPU mode, as the Raspberry Pi does not contain a dedicated GPU. Despite limited hardware resources, the lightweight YOLOv8n object detection model and optimized neural network architecture enable practical execution on the device.

#### AWS S3 Cloud Storage Integration

To manage video data efficiently, the system uses Amazon Simple Storage Service (Amazon S3) as a cloud storage platform.

Two S3 buckets are used in the system:

- **Input Bucket:** stores incoming surveillance videos.
- **Output Bucket:** stores processed and annotated videos.

The inference system periodically queries the input bucket to identify newly uploaded videos. This is implemented using the AWS Boto3 Python SDK, which allows programmatic interaction with S3 services.

The system retrieves video metadata using the following process:

- The input bucket is queried using the `list_objects_v2()` API.
- Only files with the `.mp4` extension are considered.
- The videos are sorted by their Last Modified timestamp.
- The most recently uploaded video is selected for processing.

This approach ensures that the system always processes the latest available surveillance footage. Once the video is identified, it is downloaded locally to a temporary directory on the Raspberry Pi for analysis.

#### Video Processing Pipeline

After downloading the video, the system performs a multi-stage processing pipeline combining object detection and activity classification.

The pipeline consists of the following steps:

**Frame Extraction**

The video is read frame-by-frame using OpenCV. Important video properties such as frame rate and resolution are extracted to ensure that the output video maintains the same format as the input.

**Person Detection Using YOLOv8**

Each frame is processed using the Ultralytics YOLOv8n object detection model. YOLO is a real-time object detection framework capable of identifying objects within images.

In this project, the model is used specifically to detect persons (class ID 0) within the video frame.

For each frame:

1. YOLO detects all objects in the frame.
2. The first detected person bounding box is selected.
3. The region containing the detected person is cropped.
4. The cropped image is resized to 224 × 224 pixels.

The cropped frames are stored for later use by the temporal classification model. At the same time, YOLO-generated bounding boxes are drawn on the frame to produce an intermediate annotated video showing detected persons.

**Frame Sequence Preparation**

The temporal classification model requires a fixed number of frames as input. Therefore, the system normalizes the number of extracted frames to **50 frames**.

- If the video contains more than 50 detected frames: frames are **uniformly sampled**.
- If fewer than 50 frames are detected: the last available frame is **repeated** until the required length is reached.

This guarantees that the classifier always receives a consistent input shape. The frames are then converted into a tensor format suitable for neural network processing:

```
(1, 50, 3, 224, 224)
```

Where:

- `1` = batch size
- `50` = number of frames
- `3` = RGB channels
- `224 × 224` = spatial resolution

**Shoplifting Classification Model**

The extracted frame sequence is passed to the trained shoplifting model, which performs temporal activity classification.

The model processes the sequence and produces a single scalar output value, representing the model's confidence that the video contains shoplifting activity.

A sigmoid activation function converts this value into a probability between 0 and 1:

$$P(\text{shoplifting}) = \sigma(x)$$

Where:

- $x$ is the model output logit
- $\sigma$ is the sigmoid function

If the probability exceeds the predefined threshold:

$$P(\text{shoplifting}) > 0.60$$

The system classifies the video as containing shoplifting behaviour.

#### Email Alert Notification System

When the predicted shoplifting probability exceeds the detection threshold, the system automatically generates a security alert.

The alert mechanism is implemented using the **Mailgun Email API**, which allows programmatic sending of emails through HTTP requests.

The alert system performs the following steps:

1. The model output probability is checked against the detection threshold.
2. If the threshold is exceeded, an HTTP POST request is sent to the Mailgun API.
3. An email notification is delivered to the configured recipient.

This allows security personnel to receive instant notifications when suspicious activity is detected.

#### Video Annotation and Visualization

To make the model predictions interpretable, the system generates an annotated version of the processed video.

The following information is overlayed on each frame:

1. Shoplifting probability percentage
2. Normal activity probability
3. Coloured indicator box representing the classification result

The overlay colour indicates the predicted state:

- 🔴 **Red** – shoplifting detected
- 🟢 **Green** – normal activity

The annotation box is dynamically scaled relative to the video resolution to ensure that it does not obstruct a large portion of the frame.

#### Output Video Generation and Upload

Once the annotated video is generated, it is encoded into the **H.264** video format using FFmpeg. This ensures compatibility with web browsers and video playback platforms.

The processed video is then uploaded back to the Amazon S3 output bucket using the Boto3 SDK.

#### End-to-End System Workflow

The complete deployment pipeline operates as follows:

1. Surveillance video is uploaded to the S3 input bucket.
2. The Raspberry Pi inference system retrieves the latest video.
3. The video is processed using YOLO person detection.
4. Cropped person frames are analysed using the shoplifting classification model.
5. A probability score for shoplifting is generated.
6. If the probability exceeds the threshold, an email is sent.
7. The system overlays prediction results on the video.
8. The annotated video is uploaded back to the S3 output bucket.

This architecture enables an automated surveillance pipeline capable of detecting suspicious retail behaviour and notifying security personnel in near real-time.

![Grad-Cam 1](images/processing_system.png) 


### Alternate Model Tested

During the model selection phase of this project, another architecture was evaluated and fine-tuned to determine the most effective approach for detecting shoplifting behaviour in video footage. The primary alternative model tested consists of EfficientNetV2 combined with a Temporal Transformer, with the feature extractor initialized using weights derived from ResNet-50. 

In this architecture, EfficientNetV2 was used as the core visual feature extractor. Each frame of the input video was processed by the network to identify important visual patterns such as objects, movements, and interactions occurring within the scene. Using weights pretrained from ResNet-50 allowed the model to begin with a strong understanding of common visual features, which helped accelerate training and improve generalization when working with a limited dataset. 

Once visual features were extracted from individual frames, a Temporal Transformer was applied to analyse how these features evolved over time. Shoplifting behaviour typically involves a sequence of actions rather than a single isolated frame. The Temporal Transformer therefore examined the relationships between multiple frames in the video, enabling the model to capture patterns such as suspicious hand movements, concealment actions, or unusual behaviour near store shelves.

Although this architecture demonstrated the ability to learn meaningful temporal patterns, it relied solely on full-frame analysis of the video. As a result, the model had to process large amounts of visual information that was not directly relevant to the behaviour being analysed. This increased computational overhead and sometimes reduced the model’s ability to focus specifically on individuals and objects of interest.

After comparative evaluation, this approach was not selected as the final model for the project. Instead, the final system incorporated **YOLOv8n alongside EfficientNetV2 and the Temporal Transformer. The addition of YOLOv8n allowed the system to first detect and isolate relevant objects (such as people and products) before behavioural analysis was performed. This improved efficiency and helped the model concentrate on the most relevant parts of the scene, resulting in better overall performance for the shoplifting detection task.

### 3.3. The History Page

Using the API calls discussed previously we can now access the marked videos that are stored in the S3 bucket. However, maintaining fast response times is essential and downloading possibly 100s of megabytes of videos every time you load the history page would introduce unnecessary latency. Instead, the AWS SDK lets us generate a **presigned URL**, which lets the user play the video in their browser, improving performance.

```python
links = []
paginator = s3.get_paginator("list_objects_v2")

for page in paginator.paginate(Bucket='t13-marked-videos', Prefix=user):
    for video in page.get("Contents", []):
        key = video["Key"]

        links.append(s3.generate_presigned_url(
            ClientMethod="get_object",
            Params={
                "Bucket": "t13-marked-videos",
                "Key": key
            },
            ExpiresIn=86400
        ))

return links
```

The above code utilizes a 'paginator' to automatically handle requesting successive objects in the bucket. We can then iterate through each video stored in the bucket and generate a presigned URL (a URL that allows temporary access to an object) — storing each URL in a list of links, removing the need to manually handle paginated responses.

When the list of links is returned to the Flutter client, it can then parse through each link in the response and generate an instance of the `Incident` class. The presigned URL is assigned to the Incident's `hidden_url` which is called later when the user clicks on the corresponding incident tab. We also timestamp each incident by calculating the difference between `DateTime.now()` and the time that the object was uploaded to the bucket.

```dart
for (String url in urls) {
    int descSelector = Random().nextInt(descriptions.length);
    listIncidents.add(
        Incident(
            id: listIncidents.length.toString(),
            hidden_id: url,
            timestamp: DateTime.now().subtract(Duration(minutes: randTime)),
            cameraName: 'Main Lobby Camera',
            severity: IncidentSeverity.high,
            description: descriptions[descSelector],
            reviewed: false,
        ),
    );
}
```

Incidents are assigned different severity levels in the app. **High** for an unreviewed incident, **Critical** for a 'true positive', **Low** for a 'false positive', and **Medium** if the user reviews an incident but can't decide whether shoplifting has occurred. The list of incidents are then assigned as a child of a `ListView` widget, which displays a clean, scrollable list in the app.

![App 1](images/app1.png) ![App 2](images/app2.png) 



---

## 4. Challenges Faced & Lessons Learned

### 4.1. Acquiring the Dataset

A major challenge encountered during the development of our project was the difficulty in acquiring a suitable dataset of videos. Machine learning models, particularly those used for computer vision and behavioural analysis, require large volumes of labelled training data in order to accurately detect patterns associated with theft-related activities. However, obtaining real-world data representing shoplifting incidents proved to be significantly constrained due to privacy, security, and legal considerations. This is primarily due to most retail organizations not publicly releasing their CCTV recordings, in order to protect customer privacy, prevent misuse of surveillance data, and comply with data protection regulations.

Due to this constraint, we had to rely on a mix of both real-world CCTV footage and synthetic, staged theft scenarios. Although this can provide useful training data, they don't fully capture the diversity and unpredictability of real-world retail environments.

An additional challenge during this process involved the manual labelling of approximately 600 video clips per person. Each clip had to be individually reviewed and categorized to determine whether it contained shoplifting behaviour or normal customer activity. This process was incredibly time consuming and also introduces the possibility of human error or subjective interpretation, particularly when distinguishing between suspicious behaviour and legitimate customer actions.

Links to the videos that made up our final dataset have been added to the references section.

### 4.2. Storage Issues

Early on we knew that we would be stuck for storage space. The ~950 or so training videos for the model took up 5.45GB of storage space and despite having access to some of the most powerful computers in the building, our student accounts were still limited to 1.5GB of disk space.

That's why AWS Simple Storage Services (S3) was our first choice for cloud storage. Using the AWS SDK installed in Python, we could efficiently upload/download data from an S3 bucket from any machine. This was a robust and efficient solution not only for training the model, but also for displaying videos to the user in the application.

### 4.3. Learning Google Firebase

As this project represented the first time working with Firebase, important lessons were learned during the implementation of the authentication system. Unlike traditional backend development, where authentication logic is typically implemented directly on a server, Firebase provides a managed environment where much of the authentication is handled automatically through its SDK and console.

One of the key insights gained was the importance of correctly configuring Firebase authentication within the Firebase console before attempting to implement it within the application code. Authentication providers such as email/password and Google sign-in must be explicitly enabled within the console as is shown below:

![Grad-Cam 1](images/login.png) 

Another great lesson learned was comprehending the value of Firebase's built-in functionality. Features such as email verification, password reset, and Google account sign-in were relatively straightforward to implement once the basic Firebase initialization was correctly configured. This demonstrated how managed backend services can significantly reduce development time by providing pre-built solutions for common authentication tasks.

However, as a first-time user, debugging issues was sometimes challenging because errors could originate either from the application code or from configuration settings within the Firebase console, and it was difficult at times to distinguish which aspect needed resolving.

Overall, Firebase proved to be an effective and efficient solution for implementing secure user authentication without the need to build a custom backend infrastructure, greatly simplifying complexity.

### 4.4 Camera Integration Challenges

Integrating the Raspberry Pi HQ Camera (Sony IMX477 sensor) with the Pi 5 presented one of the most persistent hurdles in the project, stemming from hardware incompatibilities (incorrect cable types), intermittent connectivity issues, and optical alignment problems. These challenges not only delayed initial prototyping but also highlighted the intricacies of working with CSI-based imaging in embedded systems.

Early attempts to detect the camera consistently failed, manifesting as "No cameras available!" errors when running `rpicam-hello --list-cameras` (with additional "Could not open any dmaHeap device" warnings). Kernel logs via `dmesg` revealed I2C communication failures: `"rp1-cfe ...: found subdevice /axi/pcie@.../imx477@1a"` followed by `"imx477 10-001a: failed to read chip id 477, with error -5"` and `"imx477 10-001a: probe with driver imx477 failed with error -5"` indicating the Pi could not properly query the sensor's identity (error -5 = EIO / I/O error). Additionally, `i2cdetect -y 10` either showed no device at the expected 0x1a address or intermittent detection, suggesting flaky electrical connections or configuration mismatches.

To troubleshoot, we systematically iterated through hardware and software fixes. The root incompatibility was the Pi 5's use of 22-pin (0.5mm pitch) CSI ports versus the HQ Camera's standard 15-pin (1mm pitch) flex cable, which we addressed by acquiring a 22-to-15-pin adapter. Even with the adapter, detection issues persisted, leading to over 20 reseating attempts, carefully inserting and removing the cable while ensuring proper alignment. We tested both CSI ports (CAM0 and CAM1), tried every possible orientation combination (metal contacts down, stiffener up on both ends). On the software side, we edited `/boot/firmware/config.txt` to include `dtoverlay=imx477` (explicitly loading the IMX477 driver) and `camera_auto_detect=0` (disabling auto-detection to force manual configuration), followed by reboots. We installed/updated `libcamera-apps` multiple times (`sudo apt install libcamera-apps -y`) and ran diagnostics like `rpicam-hello --list-cameras`.

To rule out a faulty Pi board, we replicated the setup on a second Pi 5 (4GB variant), encountering identical errors, confirming the issue was not hardware-specific to the primary device.

The breakthrough came after exhaustive checks: the 500mm third-party adapter had unreliable contact on I2C lines (SDA/SCL), with the long cable and marginal pin seating causing signal degradation or intermittent connection → I2C read failures (-5). We watched some tutorials on YouTube and properly secured the adapter and lens mount, which corrected the alignment and eliminated the I2C read failures. We then removed the CS mount for the camera not showing anything when in preview mode. This also resolved subsequent focusing issues, where initial headless captures (e.g., via `rpicam-still --nopreview`) produced blurry or poorly exposed images due to the misaligned focal plane (likely from default settings without preview tuning). With the setup properly secured, we achieved sharp focus through manual adjustments of the 6mm CS-mount lens ring (by unscrewing the smaller one partly to focus) while monitoring live preview in RDP (`rpicam-hello --qt-preview`), iteratively tweaking while monitoring output to optimize for retail scene clarity (e.g., distinguishing subtle item concealment in low-light aisles, resulting in grainy/low-light quality matching typical CCTV).

Running camera previews added another layer of complexity, particularly in our RDP-based remote setup (via xrdp over Tailscale). Graphical preview windows failed with Qt/XCB errors like `"Made QT preview window"` followed by `"qt.qpa.xcb: could not connect to display :10.0"`, `"Could not load the Qt platform plugin 'xcb'"`, or `"This application failed to start because no Qt platform plugin could be initialized"`, with the window appearing for 1–3 seconds before aborting. Attempts with `--drm`, `--egl`, or `--x11` also failed or showed "Preview window unavailable". We worked around this by using the `--nopreview` flag for non-interactive captures and ultimately running `rpicam-hello --qt-preview --width 1280 --height 720 --timeout 0` for a preview window to pop up in the terminal in the RDP session. High-resolution attempts triggered dmaHeap allocation failures (due to insufficient contiguous memory), mitigated by setting `gpu_mem=512` and `cma=1024` in `/boot/config.txt` to allocate more GPU and CMA memory, or by downscaling resolutions for stability.

---

## 5. Conclusions

As this was our first time developing a large system collaboratively over an extended period of time, we managed to successfully avoid the entire project breaking down by maintaining constant communication — preventing the build-up of small errors that go unseen until the very end.

Although there was some accidental complexity introduced by our choice of tech stack (such as deciding to do the inference on a Raspberry Pi 5), we were able to minimize this with extensive planning in the early stages of development by mapping out dataflow diagrams and defining a minimum viable product with user stories.

Another aspect of development included the use of large language models such as ChatGPT and Anthropic Claude; while these were helpful for debugging and problem exploration, they were no silver bullet. Early attempts at asking these tools to provide a roadmap for development were met with many roadblocks that the model didn't even see. In our experience, these tools were not a suitable substitution for critical thinking and our own domain knowledge.

---

## 6. Contributions

**Advait:**

- Setup the acquired GPU Machine.
- Researched on development of Machine Learning models related to the project by acquiring relevant research papers.
- Designed and Implemented Machine Learning model for the project.
- Deployed model on Raspberry Pi 5.
- Labelled ~600 videos.

**Jack:**

- Setup and managed AWS S3 buckets for storage and retrieval of data.
- Managed AWS IAM users for security and access to the buckets.
- Labelled ~600 videos.
- Started work on the Flutter application, modularized it to allow for a smoother workflow, created a page to setup and monitor cameras, updated history page to fetch 'incidents' from the S3 buckets, extensive work on UI and bug fixes.
- Recorded & edited demonstration video.

**Masood:**

- Secured hardware.
- Set up HQ Camera compatibility, traded AI for flexibility.
- Labeled 600 videos for shoplifting/normal behaviors.
- Headless Pi setup via Imager, SSH, Tailscale for multi-network access.
- Debugged camera detection with reseating, config overlays, diagnostics.
- Fixed focusing by removing CS mount, manual lens adjustments.
- Built History page with incident lists, filters, S3 playback.
- Developed Settings page for thresholds, preferences, push notifications, account deletion, changing login details etc.
- Integrated FCM for detection alerts via Pi scripts.
- Resolved FCM frontend issues with token/listener fixes.

**Sakib:**

- Acquired dataset for machine learning model training. Approximately 950 videos were attained.
- Labelled ~600 videos.
- Worked on Flutter application, working on the UI for landing and home page, as well as producing the pages for registration/login system and the functional elements of settings page.
- Replicated backend logic added on camera and history page to function on home page, simplifying the application for users.
- Implemented user authentication using Google Firebase, including features such as email/password sign-in, Google sign-in, email verification, password recovery and account deletion.

---

## 7. Acknowledgments

We would like to express our sincere gratitude to the following individuals whose support was instrumental in making this project possible:

- **Professor Dirk Pesch**, Head of the School of Computer Science and Information Technology at University College Cork, for generously providing the Raspberry Pi 5, Raspberry Pi HQ Camera, 6mm CS-mount lens, and 15-to-22 pin CSI adapter cable. His facilitation of these essential hardware resources enabled the core edge-based implementation and experimentation in TheftSense.

- **Professor Ahmed Zahran**, for kindly offering access to the NVIDIA Jetson Nano and for proactively requesting the Raspberry Pi hardware and components from Prof. Pesch on our behalf. This assistance was crucial for exploring cross-platform performance options.

- **Ms. Julie Walsh**, Executive Assistant in the School of Computer Science and Information Technology at UCC, for efficiently handling the procurement and ordering of the camera lens, adapter cable, and related components through the School's accounts. Her prompt and reliable support ensured we received the necessary items without delay.

- **Mr. Chris Baker**, Senior Systems Administrator in the School of Computer Science and Information Technology at UCC, for granting us access to powerful computers equipped with GPUs. This allowed us to train our machine learning model locally, overcoming significant storage and compute limitations on standard student machines.

- **Dr. Klaas-Jan Stol**, for supervising the project, providing valuable guidance and advice throughout the development process, and helping us resolve numerous technical issues. His expertise and mentorship greatly contributed to the successful completion of TheftSense.

Their collective support, from hardware provisioning and administrative facilitation to technical advice and resource access, played a pivotal role in turning our project vision into reality. We are truly appreciative of their generosity and commitment to student projects.

---

## 8. References

1. [New study reveals jarring levels of crime experienced by Irish shop owners](https://extra.ie/2024/11/17/news/crime-irish-shop-owners)
2. [Irish Small and Medium Enterprises Association (ISME) estimates, cited in multiple sources incl. Irish Mirror (2023), Irish Times (2024–2025)](https://www.irishmirror.ie/news/irish-news/gardai-cracking-down-retail-crime-31651683).
3. [An Garda Síochána reports on retail crime operations (2023–2025)](https://retailsolutions.ie/blog/retail-security-in-ireland-tackling-the-surge-in-shoplifting/).
4. [Intentional Office Videos Dataset — Available from the Mendeley Data repository](https://data.mendeley.com/datasets/r3yjf35hzr/1)
5. [Intentional Shop Videos Dataset — Available from Zenodo, an open-access research data platform](https://zenodo.org/records/10149996)
6. [UCF Shoplifting Video Dataset — Public dataset hosted on Kaggle, containing surveillance-style videos used for anomaly detection research](https://www.kaggle.com/datasets/minhajuddinmeraj/anomalydetection-dataset-ucf)
7. [Early Detection of Collective or Individual Theft Attempts Dataset (Real CCTV Footage) — Supplementary dataset containing real CCTV recordings used for behavioural analysis and theft detection research](https://www.mediafire.com/file/jhegpgfiihhgj0y/Early_Detection_of_Collective_or_Individual_Theft_Attempts_Using_Long-term_Recurrent_Convolutional_Networks.zip/file)
8. [Smart Surveillance: Real-Time Shoplifting Detection Using Deep Learning and YOLOv8](https://ieeexplore.ieee.org/document/11132287)
9. [Detection of pre shoplifting suspicious behavior using deep learning](https://ieeexplore.ieee.org/abstract/document/10707900?casa_token=377i4tpt44EAAAAA:qGPElVZesiuLeqbUIVmaH66lfC5TYwSJH-vohK9ptKenlqHPm_hCAovrQxCmUqqagltsyh8)
10. [Suspicious Behavior Detection with Temporal Feature Extraction and Time-Series Classification for Shoplifting Crime Prevention (Sensors, 2023)](https://www.mdpi.com/1424-8220/23/13/5811)