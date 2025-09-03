from django.shortcuts import render
from django.http import JsonResponse
from .models import Product

def product_list(request):
    products = Product.objects.all()
    context = {'products': products}
    return render(request, 'store/product_list.html', context)

def health_check(request):
    return JsonResponse({'status': 'ok'})