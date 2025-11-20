import 'package:saladafactory/features/home/data/services/fetchandCacheProducts.dart';
import 'package:saladafactory/features/home/data/services/fetchandCacheSupplier.dart';
import 'package:saladafactory/features/home/data/services/fetchandCacheUnit.dart';
import 'package:saladafactory/features/home/data/services/fetchandCacheUserDep.dart';

class Cachehelper {
  static var loadCacheSuppliers;
  static var loadCacheUnits;
  static var loadCacheProducts;
  static var loadCachedUserDep;

  fetchDataandStoreLocaallly() async {
    await SupplierSS.fetchAndCacheSuppliers();
    await Unitss.fetchAndCacheUnits();
    await SupplierSS.loadCachedSuppliers().then((cached) {
      loadCacheSuppliers = cached;
      print(cached);
    });
    await Unitss.loadCachedUnits().then((cached) {
      loadCacheUnits = cached;
      print(cached);
    });

  await  UserDepartment.fetchAndCacheUserDep();
  await  UserDepartment.loadCachedUserDep().then((cached) {
      loadCachedUserDep = cached;
      print("userDep ::::: ${cached}");
    });
    await ProductsS.fetchAndCacheProducts();
        print("=============================fetchProductCachedSucces===================================");

    await ProductsS.loadCachedProducts().then((cached) {
      print("locall product  $cached");
      loadCacheProducts = cached;
    });
    print("=============================fetchDataandCachedSucces===================================");
  }

  
}
