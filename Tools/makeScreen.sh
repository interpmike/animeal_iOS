#!/bin/bash

name=$1
file_module_name=$2

if [ "$file_module_name" == "" ]; then
    file_module_name=$(echo "$name")
fi

if [ "$name" != "" ]; then
    module_name=$(echo "$name")
fi

if [ "$module_name" != "" ]; then
    mkdir -p "$file_module_name"
    cd $file_module_name

echo "import UIKit

// MARK: - View
protocol ${module_name}Viewable: AnyObject {
}

// MARK: - ViewModel
typealias ${module_name}ViewModelProtocol = ${module_name}ViewModelLifeCycle
    & ${module_name}ViewInteraction
    & ${module_name}ViewState

protocol ${module_name}ViewModelLifeCycle: AnyObject {
    func setup()
    func load()
}

protocol ${module_name}ViewInteraction: AnyObject {
}

protocol ${module_name}ViewState: AnyObject {
}

// MARK: - Model

// sourcery: AutoMockable
protocol ${module_name}ModelProtocol: AnyObject {
}" > ${file_module_name}Contract.swift
echo "${file_module_name}Contract was created"


echo "import UIKit
import Common

final class ${module_name}ModuleAssembler: Assembling {
    static func assemble() -> UIViewController {
        let model = ${module_name}Model()
        let viewModel = ${module_name}ViewModel(
            model: model
        )
        let view = ${module_name}ViewController(viewModel: viewModel)

        return view
    }
}" > ${file_module_name}Assembler.swift
echo "${file_module_name}Assembler was created"

echo "import Foundation

final class ${module_name}ViewModel: ${module_name}ViewModelLifeCycle, ${module_name}ViewInteraction, ${module_name}ViewState {

    // MARK: - Dependencies
    private let model: ${module_name}ModelProtocol

    // MARK: - Initialization
    init(
        model: ${module_name}ModelProtocol
    ) {
        self.model = model
        setup()
    }

    // MARK: - Life cycle
    func setup() {
    }

    func load() {
    }
}" > ${file_module_name}ViewModel.swift
echo "${file_module_name}ViewModel was created"

echo "import UIKit
import UIComponents

final class ${module_name}ViewController: UIViewController, ${module_name}Viewable {
    // MARK: - UI properties
    private let viewModel: ${module_name}ViewModelProtocol

    // MARK: - Initialization
    init(viewModel: ${module_name}ViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError(\"init(coder:) has not been implemented\")
    }

    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setup()
        viewModel.load()
    }

    // MARK: - Setup
    private func setup() {
    }
}" > ${file_module_name}ViewController.swift
echo "${file_module_name}ViewController was created"

echo "import Foundation

final class ${module_name}Model: ${module_name}ModelProtocol {
    // MARK: - Private properties

    // MARK: - Initialization
    init() { }
}" > ${file_module_name}Model.swift
echo "${file_module_name}Model was created"
    open .
else
    echo "[ERROR] Provide screen name"
    exit 0
fi
