//
//  MainViewController.swift
//  XX
//
//  Created by 박은비 on 19/10/2019.
//  Copyright © 2019 YAPP. All rights reserved.
//
import UIKit

class MainViewController: BaseViewController {
 
    @IBOutlet weak var collectionView: UICollectionView!
    
    let HEADER_CELL_NAME = "MainHeaderCell"
    let MAIN_CELL_NAME = "MainCollectionViewCell"
    
    let MAIN_CELL_WIDTH = UIScreen.main.bounds.width * 0.405
    var viewModel: MainViewModel?
    
    var reloadCollectionViewClosure: (() -> Void)?
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        bindCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.navigationController?.setNavigationBarHidden(true, animated: true)
    }
}

extension MainViewController: ViewModelBindableType {
    func bindViewModel() {
        guard let viewModel = viewModel else { return }
        
        MondeyHelper.shared.mondeyMainAddHelper = {
            (categoryIdx, idx, name, money) -> Void in
            
            var category = Category()
            
            category.id              = idx
            category.tintColor       = MondeyHelper.mondeyCategoryTitleColor[categoryIdx-1]
            category.title           = ""
            category.subTitle        = ""
            category.name            = name
            category.active          = true
            category.budget          = money
            category.period          = nil
            
            
            viewModel.addItem(category: category)
        }
        
        MondeyHelper.shared.mondeyMainRemoveHelper = {
            (idx) -> Void in
            viewModel.removeItem(at: idx)
        }
    }
    
    private func bindCollectionView() { 
        guard let viewModel = viewModel else { return }
        
        viewModel.sectionListSubject.asObserver()
        .bind(to: collectionView.rx.items(dataSource: mainDatasource)).disposed(by: rx.disposeBag)
  
        collectionView
            .rx.itemSelected.bind { (indexPath) in
                // 셀쪽 이벤트 RX에 대해 알아봐야할듯 이 방법이 맞는지 모르겠음
                if viewModel.isMainCellRemoveMode.value {
                    viewModel.requestSpendDetailMoveAction().execute()
                }
            }
            .disposed(by: rx.disposeBag)
        
        collectionView
            .rx.setDelegate(self)
            .disposed(by: rx.disposeBag)
        
        
        
    }
    

    
    typealias MainSectionModel = SectionModel<String, Category>
    typealias MainCollectionViewDataSource = RxCollectionViewSectionedReloadDataSource<MainSectionModel>
    
    private var mainDatasource: MainCollectionViewDataSource {
        let configureCell: (CollectionViewSectionedDataSource<MainSectionModel>, UICollectionView, IndexPath, Category) -> UICollectionViewCell =
        { (datasource,
            collectionView,
            indexPath,
            element) in
            guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: self.MAIN_CELL_NAME, for: indexPath) as? MainCollectionViewCell
                else { return UICollectionViewCell() }
            //            print("element 조회 \(element)")
            
            cell.cellIdx = indexPath.item
            if let viewModel = self.viewModel {
                cell.viewModel = viewModel
                cell.category.accept(element)
                
                cell.filterCateogryAllValue.accept(
                    MemoryStorage.shared.expenditures
                    .filter{ $0.id == element.id }
                    .map{ $0.cost }
                    .reduce(0, { $0 + $1 })
                )
                
                viewModel
                    .isMainCellRemoveMode
                    .subscribe
                    { (value) in
                        cell.removeCellButton.rx.isHidden.on(value)
                    }
                    .disposed(by: self.rx.disposeBag)
            }
            
            return cell
        }
        
        let datasource = MainCollectionViewDataSource.init(configureCell: configureCell)
        
        
        datasource.configureSupplementaryView = {
            (dataSource,
            collectionView,
            kind,
            indexPath) -> UICollectionReusableView in
            if let header = collectionView.dequeueReusableSupplementaryView(ofKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: self.HEADER_CELL_NAME, for: indexPath) as? MainHeaderReusableView {
                
                if let viewModel = self.viewModel {
                    header.viewModel = viewModel
                }
                
                return header
            }
            
            return UICollectionReusableView()
        }
        
        return datasource
        
    }
    
    
    
}

extension MainViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: MAIN_CELL_WIDTH,
                      height: MAIN_CELL_WIDTH)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding = (UIScreen.main.bounds.width - (MAIN_CELL_WIDTH * 2)) / 4 + 10
        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
}
