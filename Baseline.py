
# coding: utf-8

# In[153]:


from sklearn.model_selection import train_test_split, GridSearchCV, cross_val_score, RandomizedSearchCV, RepeatedStratifiedKFold
from sklearn.preprocessing import MinMaxScaler, StandardScaler
from sklearn.linear_model import LinearRegression, Lasso
from sklearn.metrics import mean_squared_error, r2_score
import math
import pandas as pd
import numpy as np
import matplotlib.pyplot as plt


# In[154]:


df = pd.read_csv(r"C:\Users\owenf\OneDrive\Desktop\NHL Analytics\full_team_data.csv")
df = pd.DataFrame(df)


# In[155]:


df.drop(df.columns[0:26], axis = 1, inplace = True)


# In[156]:


df.head()


# In[157]:


x = df.drop(['WIN.pct', 'ID'], axis=1)
y = pd.DataFrame(df['WIN.pct'])


# In[158]:


x = x.fillna(0)


# In[159]:


x.head()


# In[160]:


y.head()


# In[161]:


x.describe()


# In[162]:


scalerX = MinMaxScaler()
scalerX.fit(x)
X = pd.DataFrame(scalerX.transform(x))


# In[163]:


X.head()


# In[164]:


y = y * 100


# In[165]:


y.head()


# In[166]:


from sklearn.model_selection import train_test_split
# Split the data into training and testing sets
X_train, X_test, Y_train, Y_test = train_test_split(X, y, test_size = 0.25, random_state = 42)


# In[167]:


model = Lasso(0.05)


# In[168]:


# fit model
model.fit(X_train, Y_train)


# In[169]:


# make a prediction
yhat_train = model.predict(X_train)


# In[175]:


print('Standard Deviation: %.2f'
     % math.sqrt(mean_squared_error(Y_train, yhat_train)))


# In[176]:


print('Coefficients: \n', model.coef_[model.coef_ > 0])


# In[177]:


# make a prediction
yhat_test = model.predict(X_test)


# In[178]:


print('Standard Deviation: %.2f'
     % math.sqrt(mean_squared_error(Y_test, yhat_test)))


# In[183]:


np.where(model.coef_ > 0)

