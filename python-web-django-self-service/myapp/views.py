from django.conf import settings
import ldap
from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth.decorators import login_required
from .forms import UserProfileForm, UserSearchForm

@login_required
def home(request):
    user = request.user
    ldap_user = user.ldap_user

    form = UserProfileForm(initial={
        'first_name': ldap_user.attrs.get('givenName', [''])[0],
        'last_name': ldap_user.attrs.get('sn', [''])[0],
        'email': ldap_user.attrs.get('mail', [''])[0],
        'mobile': ldap_user.attrs.get('mobile', [''])[0],
        'address': ldap_user.attrs.get('homePostalAddress', [''])[0],
        'department_number': ldap_user.attrs.get('departmentNumber', [''])[0],
        'employee_number': ldap_user.attrs.get('employeeNumber', [''])[0],
        'employee_type': ldap_user.attrs.get('employeeType', [''])[0],
        'home_phone': ldap_user.attrs.get('homePhone', [''])[0],
        'manager': ldap_user.attrs.get('manager', [''])[0],
        'room_number': ldap_user.attrs.get('roomNumber', [''])[0],
        'photo': ldap_user.attrs.get('jpegPhoto', [None])[0],
    })

    if request.method == 'POST':
        form = UserProfileForm(request.POST, request.FILES)
        if form.is_valid():
            try:
                ldap_connection = ldap.initialize(settings.AUTH_LDAP_SERVER_URI)
                ldap_connection.simple_bind_s(settings.AUTH_LDAP_BIND_DN, settings.AUTH_LDAP_BIND_PASSWORD)
                dn = f"uid={user.username},ou=users,dc=mylab,dc=lan"
                mod_attrs = []

                if form.cleaned_data['first_name']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'givenName', [form.cleaned_data['first_name'].encode()]))
                if form.cleaned_data['last_name']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'sn', [form.cleaned_data['last_name'].encode()]))
                if form.cleaned_data['email']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'mail', [form.cleaned_data['email'].encode()]))
                if form.cleaned_data['mobile']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'mobile', [form.cleaned_data['mobile'].encode()]))
                if form.cleaned_data['address']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'homePostalAddress', [form.cleaned_data['address'].encode()]))
                if form.cleaned_data['department_number']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'departmentNumber', [form.cleaned_data['department_number'].encode()]))
                if form.cleaned_data['employee_number']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'employeeNumber', [form.cleaned_data['employee_number'].encode()]))
                if form.cleaned_data['employee_type']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'employeeType', [form.cleaned_data['employee_type'].encode()]))
                if form.cleaned_data['home_phone']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'homePhone', [form.cleaned_data['home_phone'].encode()]))
                if form.cleaned_data['manager']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'manager', [form.cleaned_data['manager'].encode()]))
                if form.cleaned_data['room_number']:
                    mod_attrs.append((ldap.MOD_REPLACE, 'roomNumber', [form.cleaned_data['room_number'].encode()]))
                if 'photo' in form.cleaned_data and form.cleaned_data['photo']:
                    photo_data = form.cleaned_data['photo'].read()
                    mod_attrs.append((ldap.MOD_REPLACE, 'jpegPhoto', [photo_data]))

                if mod_attrs:
                    ldap_connection.modify_s(dn, mod_attrs)
                ldap_connection.unbind_s()
            except ldap.LDAPError as e:
                print(f"LDAP error: {e}")
            return redirect('home')

    return render(request, 'home.html', {'form': form, 'photo': form.initial['photo']})

@login_required
def search_users(request):
    form = UserSearchForm(request.GET)
    results = []

    if form.is_valid():
        query = form.cleaned_data['query']
        if query:
            try:
                ldap_connection = ldap.initialize(settings.AUTH_LDAP_SERVER_URI)
                ldap_connection.simple_bind_s(settings.AUTH_LDAP_BIND_DN, settings.AUTH_LDAP_BIND_PASSWORD)
                search_filter = f"(givenName=*{query}*)"
                base_dn = "ou=users,dc=mylab,dc=lan"
                search_scope = ldap.SCOPE_SUBTREE
                retrieve_attributes = ['jpegPhoto', 'givenName', 'sn', 'mail', 'mobile', 'uid']
                ldap_result_id = ldap_connection.search(base_dn, search_scope, search_filter, retrieve_attributes)
                while True:
                    result_type, result_data = ldap_connection.result(ldap_result_id, 0)
                    if result_data == []:
                        break
                    if result_type == ldap.RES_SEARCH_ENTRY:
                        entry = result_data[0][1]
                        results.append({
                            'uid': entry.get('uid', [''])[0].decode('utf-8') if entry.get('uid') else '',
                            'photo': entry.get('jpegPhoto', [None])[0],
                            'name': f"{entry.get('givenName', [''])[0].decode('utf-8') if entry.get('givenName') else ''} {entry.get('sn', [''])[0].decode('utf-8') if entry.get('sn') else ''}",
                            'email': entry.get('mail', [''])[0].decode('utf-8') if entry.get('mail') else '',
                            'mobile': entry.get('mobile', [''])[0].decode('utf-8') if entry.get('mobile') else '',
                        })
                ldap_connection.unbind_s()
            except ldap.LDAPError as e:
                print(f"LDAP error: {e}")

    return render(request, 'search_results.html', {'form': form, 'results': results})


@login_required
def user_profile(request, uid):
    try:
        ldap_connection = ldap.initialize(settings.AUTH_LDAP_SERVER_URI)
        ldap_connection.simple_bind_s(settings.AUTH_LDAP_BIND_DN, settings.AUTH_LDAP_BIND_PASSWORD)
        dn = f"uid={uid},ou=users,dc=mylab,dc=lan"
        search_scope = ldap.SCOPE_BASE
        retrieve_attributes = ['jpegPhoto', 'givenName', 'sn', 'mail', 'mobile', 'homePostalAddress', 'departmentNumber', 'employeeNumber', 'employeeType', 'homePhone', 'manager', 'roomNumber']
        ldap_result_id = ldap_connection.search(dn, search_scope, "(objectClass=*)", retrieve_attributes)
        result_type, result_data = ldap_connection.result(ldap_result_id, 0)
        if result_data:
            entry = result_data[0][1]
            user_data = {
                'photo': entry.get('jpegPhoto', [None])[0],
                'first_name': entry.get('givenName', [''])[0],
                'last_name': entry.get('sn', [''])[0],
                'email': entry.get('mail', [''])[0],
                'mobile': entry.get('mobile', [''])[0],
                'address': entry.get('homePostalAddress', [''])[0],
                'department_number': entry.get('departmentNumber', [''])[0],
                'employee_number': entry.get('employeeNumber', [''])[0],
                'employee_type': entry.get('employeeType', [''])[0],
                'home_phone': entry.get('homePhone', [''])[0],
                'manager': entry.get('manager', [''])[0],
                'room_number': entry.get('roomNumber', [''])[0],
            }

            # Decode byte strings to regular strings, except for 'photo'
            for key, value in user_data.items():
                if isinstance(value, bytes) and key != 'photo':
                    user_data[key] = value.decode('utf-8')
        else:
            user_data = {}
        ldap_connection.unbind_s()
    except ldap.LDAPError as e:
        print(f"LDAP error: {e}")
        user_data = {}

    return render(request, 'user_profile.html', {'user_data': user_data})