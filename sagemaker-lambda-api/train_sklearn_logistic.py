import argparse
import os
import pandas as pd
import joblib
from sklearn.linear_model import LogisticRegression

def parse_args():
    parser = argparse.ArgumentParser()

    # SageMaker inputs
    parser.add_argument("--train", type=str, default=os.environ.get("SM_CHANNEL_TRAIN"))
    parser.add_argument("--model-dir", type=str, default=os.environ.get("SM_MODEL_DIR"))

    # Hyperparameters
    parser.add_argument("--max-iter", type=int, default=100)
    parser.add_argument("--class-weight", type=str, default="balanced")  # important for imbalance

    return parser.parse_args()

'''
Action	Function called
.fit() ->	main()
.deploy() ->	model_fn()
.predict() ->	input_fn() → predict_fn()
'''

def main():
    args = parse_args()

    print("main function got called")

    # Load data
    train_file = os.path.join(args.train, "train.csv")
    df = pd.read_csv(train_file, header=None)

    y = df.iloc[:, 0]
    X = df.iloc[:, 1:]

    # Handle class weight
    class_weight = "balanced" if args.class_weight == "balanced" else None

    # Train Logistic Regression
    model = LogisticRegression(
        max_iter=args.max_iter,
        class_weight=class_weight,
        solver="lbfgs"
    )

    try:
        model.fit(X, y)
        print("[DEBUG] Model fitting completed successfully.")
    except Exception as e:
        print(f"[ERROR] Failed to fit model: {e}")
        raise

    # Save model
    model_path = os.path.join(args.model_dir, "model.joblib")
    joblib.dump(model, model_path)

    print(f"Model saved to {model_path}")

# This part is addition 

def model_fn(model_dir):
    import joblib
    import os
    
    print("model function got called")
    model_path = os.path.join(model_dir, "model.joblib")
    
    return joblib.load(model_path)

    #return joblib.load(model_dir,os.path.join(model_dir, "model.joblib"))


def predict_fn(input_data, model):
    print("prediction get called")
    return model.predict(input_data)

def input_fn(request_body, request_content_type):
    import pandas as pd
    from io import StringIO

    print("input got called")

    if request_content_type == "text/csv":
        return pd.read_csv(StringIO(request_body), header=None)

# end of addition

if __name__ == "__main__":
    main()