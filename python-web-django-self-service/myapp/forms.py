from django import forms

class UserProfileForm(forms.Form):
    first_name = forms.CharField(max_length=30, required=True)
    last_name = forms.CharField(max_length=30, required=True)
    email = forms.EmailField(required=True)
    mobile = forms.CharField(max_length=15, required=False)
    address = forms.CharField(widget=forms.Textarea, required=False)
    department_number = forms.CharField(max_length=30, required=False)
    employee_number = forms.CharField(max_length=30, required=False)
    employee_type = forms.CharField(max_length=30, required=False)
    home_phone = forms.CharField(max_length=15, required=False)
    manager = forms.CharField(max_length=30, required=False)
    room_number = forms.CharField(max_length=30, required=False)
    photo = forms.ImageField(required=False)
class UserSearchForm(forms.Form):
    query = forms.CharField(max_length=100, required=False, label='Search by First Name')