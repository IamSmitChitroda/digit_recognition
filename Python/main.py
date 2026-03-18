from tensorflow import lite
from tensorflow import keras
import os
import dotenv

dotenv.load_dotenv()

if not os.path.exists(os.getenv("FILE_NAME")):
print("Lets Create Model")

(x_train, y_train), (x_test, y_test) = keras.datasets.mnist.load_data()

# Feature Scaling
x_train = x_train / 255.0
x_test = x_test / 255.0

# One hot Encoding
y_train = keras.utils.to_categorical(y_train, 10)
y_test = keras.utils.to_categorical(y_test, 10)

model = keras.models.Sequential(
[
keras.layers.Input(shape=(28, 28)),
keras.layers.Flatten(),
keras.layers.Dense(128, activation='relu'),
keras.layers.Dense(64, activation='relu'),
keras.layers.Dense(10, activation='sigmoid'),
]
)

model.compile(
optimizer='adam',
loss='categorical_crossentropy',
metrics=['accuracy'],
)

model.fit(x_train, y_train, epochs=5, batch_size=32)

model.save(os.getenv("FILE_NAME"))

print("Model Saved Successfully!!!")
else:
print("Lets Load Model")
converter = lite.TFLiteConverter.from_saved_model(os.getenv("FILE_NAME"))
converter.optimizations = [lite.Optimize.DEFAULT]

tf_model = converter.convert()

with open(os.path.join(os.getenv("FILE_NAME"), os.getenv("MODEL_NAME")), 'wb') as f:
f.write(tf_model)

print("Model Saved Successfully!!!")
